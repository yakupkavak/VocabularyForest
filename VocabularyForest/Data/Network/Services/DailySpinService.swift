//
//  DailySpinService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.06.2026.
//

import Combine
import Foundation

enum DailySpinServiceError: Error {
    case emptySpinList
    case emptySpinTrakcs
}

enum DailySpinReadyState {
    case claimable
    case alreadyClaimed(remainTime: Date)
}

protocol DailySpinServiceProtocol {
    var dailySpinListPublisher: AnyPublisher<[DailySpinModel], Never> { get }
    var dailySpinStatePublisher: AnyPublisher<DailySpinReadyState, Never> { get }
    var dailySpinList: [DailySpinModel] { get }
    var currentSpinState: DailySpinReadyState { get }
    
    func convertRemoteToDailySpinList(list: RemoteDailySpinListModel) async throws
    func checkAndUpdateSpinState() async
    func claimDailySpinReward(spinModel: DailySpinModel) async throws
}

final class DailySpinService {
    
    // MARK: - PROPERTIES
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    @Published private var activeSpinList: [DailySpinModel] = []
    @Published private var dailySpinState: DailySpinReadyState = .claimable
    
    private var stateUpdateTask: Task<Void, Never>?
    
    // MARK: - INIT
    
    init(forestManager: ForestDataManagerProtocol, rewardRepository: RewardRepositoryProtocol, activeSpinList: [DailySpinModel]) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
        self.activeSpinList = activeSpinList
    }
    
}

extension DailySpinService: DailySpinServiceProtocol {
    
    var dailySpinListPublisher: AnyPublisher<[DailySpinModel], Never> {
        $activeSpinList.eraseToAnyPublisher()
    }
    
    var dailySpinStatePublisher: AnyPublisher<DailySpinReadyState, Never> {
        $dailySpinState.eraseToAnyPublisher()
    }
    
    var dailySpinList: [DailySpinModel] {
        activeSpinList
    }
    
    var currentSpinState: DailySpinReadyState {
        dailySpinState
    }
    
    func convertRemoteToDailySpinList(list: RemoteDailySpinListModel) async throws {
        for model in list.items {
            guard let id = model.id, let weight = model.weight, let reward = model.reward else { return }
            var localReward: LocalRewardModel
            do {
                localReward = try await rewardRepository.processAndGetLocalReward(from: reward)
            } catch {
                throw RewardRepositoryError.decodingError
            }
            let dailyModel = DailySpinModel(id: id, weight: weight, reward: localReward)
            activeSpinList.append(dailyModel)
        }
    }
    
    func checkAndUpdateSpinState() async {
        stateUpdateTask?.cancel()
        
        do {
            if let targetDate = try await fetchDailySpinStatusDate() {
                let now = Date()
                if targetDate > now {
                    DispatchQueue.main.async {
                        self.dailySpinState = .alreadyClaimed(remainTime: targetDate)
                    }
                    scheduleStateUpdate(after: targetDate.timeIntervalSince(now))
                } else {
                    DispatchQueue.main.async {
                        self.dailySpinState = .claimable
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.dailySpinState = .claimable
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.dailySpinState = .claimable
            }
        }
    }
    
    func claimDailySpinReward(spinModel: DailySpinModel) async throws {
        
        await checkAndUpdateSpinState()
    }
}

private extension DailySpinService {
    
    func fetchDailySpinStatusDate() async throws -> Date? {
        do {
            let trueNow = try await NetworkTimeHelper.getTrueTime()
            let localForestRes = forestManager.fetchSafeForest(contextType: .main)
            if let forest = localForestRes.data, let lastUsed = forest.dailyActivities.dailySpinLastUsedDate {
                let localNow = Date()
                let targetTime = lastUsed.addingTimeInterval(86400)
                return targetTime > localNow ? targetTime : nil
            } else {
                return nil
            }
        } catch {
            throw error
        }
    }
    
    func scheduleStateUpdate(after seconds: TimeInterval) {
        stateUpdateTask = Task {
            let nanoseconds = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            
            DispatchQueue.main.async {
                self.dailySpinState = .claimable
            }
        }
    }
}
