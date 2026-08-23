//
//  WeeklyRewardService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.07.2026.
//

import Combine
import Foundation

enum WeeklyRewardServiceError: Error {
    case emptyRewardList
    case missingDayReward
    case notClaimable
}

protocol WeeklyRewardServiceProtocol {
    var weeklyCardListPublisher: AnyPublisher<[WeeklyDailyCardModel], Never> { get }
    var weeklyCardList: [WeeklyDailyCardModel] { get }
    
    func convertRemoteToWeeklyList(list: RemoteWeeklyListModel) async throws
    func checkAndUpdateWeeklyState() async
    func claimWeeklyReward(model: WeeklyDailyCardModel) async throws
}

final class WeeklyRewardService {
    
    // MARK: - PROPERTIES
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    private var activeRewardList: [Int: LocalRewardModel] = [:]
    @Published private var weeklyCards: [WeeklyDailyCardModel] = []
    
    private var stateUpdateTask: Task<Void, Never>?
    
    // MARK: - INIT
    
    init(forestManager: ForestDataManagerProtocol, rewardRepository: RewardRepositoryProtocol) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
    }
    
}

extension WeeklyRewardService: WeeklyRewardServiceProtocol {
    
    var weeklyCardListPublisher: AnyPublisher<[WeeklyDailyCardModel], Never> {
        $weeklyCards.eraseToAnyPublisher()
    }
    
    var weeklyCardList: [WeeklyDailyCardModel] {
        weeklyCards
    }
    
    func convertRemoteToWeeklyList(list: RemoteWeeklyListModel) async throws {
        guard !list.items.isEmpty else { throw WeeklyRewardServiceError.emptyRewardList }
        
        var rewardList: [Int: LocalRewardModel] = [:]
        
        for model in list.items {
            guard let day = model.day, let reward = model.reward, (1...7).contains(day) else { continue }
            var localReward: LocalRewardModel
            do {
                localReward = try await rewardRepository.processAndGetLocalReward(from: reward)
            } catch {
                throw RewardRepositoryError.decodingError
            }
            rewardList[day] = localReward
        }
        
        guard rewardList.count == 7 else { throw WeeklyRewardServiceError.missingDayReward }
        
        activeRewardList = rewardList
        await checkAndUpdateWeeklyState()
    }
    
    func checkAndUpdateWeeklyState() async {
        stateUpdateTask?.cancel()
        
        do {
            let trueNow = try await NetworkTimeHelper.getTrueTime()
            updateWeeklyState(now: trueNow)
        } catch {
            /// Offline fallback: keep the streak with local time instead of failing open
            updateWeeklyState(now: Date())
        }
    }
    
    func claimWeeklyReward(model: WeeklyDailyCardModel) async throws {
        let trueNow = try await NetworkTimeHelper.getTrueTime()
        let streak = fetchStreakContext(now: trueNow)
        
        guard model.day == streak.activeDay, !streak.isClaimedToday else {
            throw WeeklyRewardServiceError.notClaimable
        }
        
        try forestManager.updateWeeklyStreak(day: model.day, time: trueNow, contextType: .main)
        updateWeeklyState(now: trueNow)
    }
}

private extension WeeklyRewardService {
    
    struct WeeklyStreakContext {
        let activeDay: Int
        let isClaimedToday: Bool
    }
    
    func fixedCalendar() -> Calendar {
        var calendar = Calendar.current
        let localForestRes = forestManager.fetchSafeForest(contextType: .main)
        let identifier = localForestRes.data?.dailyActivities.fixedTimeZone ?? TimeZone.current.identifier
        calendar.timeZone = TimeZone(identifier: identifier) ?? TimeZone.current
        return calendar
    }
    
    func fetchStreakContext(now: Date) -> WeeklyStreakContext {
        let localForestRes = forestManager.fetchSafeForest(contextType: .main)
        guard let forest = localForestRes.data,
              let lastClaim = forest.dailyActivities.weeklyStreakLastClaimDate else {
            return WeeklyStreakContext(activeDay: 1, isClaimedToday: false)
        }
        
        let calendar = fixedCalendar()
        let currentDay = max(forest.dailyActivities.weeklyStreakCurrentDay, 1)
        
        if calendar.isDate(lastClaim, inSameDayAs: now) {
            return WeeklyStreakContext(activeDay: currentDay, isClaimedToday: true)
        }
        
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(lastClaim, inSameDayAs: yesterday) {
            let nextDay = currentDay >= 7 ? 1 : currentDay + 1
            return WeeklyStreakContext(activeDay: nextDay, isClaimedToday: false)
        }
        
        /// Streak is broken, start over from the first day
        return WeeklyStreakContext(activeDay: 1, isClaimedToday: false)
    }
    
    func updateWeeklyState(now: Date) {
        guard !activeRewardList.isEmpty else { return }
        
        let streak = fetchStreakContext(now: now)
        var cards: [WeeklyDailyCardModel] = []
        
        for day in 1...7 {
            guard let bounty = activeRewardList[day] else { continue }
            let status: BountyStatus
            if day < streak.activeDay {
                status = .claimed
            } else if day == streak.activeDay {
                status = streak.isClaimedToday ? .claimed : .ready
            } else {
                status = .locked
            }
            cards.append(WeeklyDailyCardModel(day: day, bounty: bounty, status: status))
        }
        
        DispatchQueue.main.async {
            self.weeklyCards = cards
        }
        scheduleNextDayUpdate(now: now)
    }
    
    func scheduleNextDayUpdate(now: Date) {
        stateUpdateTask?.cancel()
        
        let calendar = fixedCalendar()
        guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return }
        
        let seconds = nextDayStart.timeIntervalSince(now)
        guard seconds > 0 else { return }
        
        stateUpdateTask = Task {
            let nanoseconds = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            
            await self.checkAndUpdateWeeklyState()
        }
    }
}
