//
//  ForestAdventureService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.04.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData
import DependencyContainer

// MARK: - ADVENTURE ERROR

enum ForestAdventureError: LocalizedError {
    case networkError
    case unauthenticated
    case emptyForestData
    var errorDescription: String? {
        switch self {
        case .networkError:
            return String(localized: "Network error occurred. Please check your connection.")
        case .unauthenticated:
            return String(localized: "You must be authenticated to use the reward system.")
        case .emptyForestData:
            return String(localized: "Local forest data is not available.")
        }
    }
}

// MARK: - PROTOCOL

protocol ForestAdventureServiceProtocol {
    func fetchWeeklyDailyRewards() async -> Resource<[WeeklyDailyCardModel]>
    func fetchDailySpinStatusDate() async -> Resource<Date?>
    func claimDailySpinReward(reward: QuestRewardModel, contextType: ForestDataManager.ContextType) async -> Resource<Bool>
    func saveWeeklyReward(weeklyModel: WeeklyDailyCardModel, contextType: ForestDataManager.ContextType) async -> Resource<Bool>
}

// MARK: - FOREST ADVENTURE SERVICE

class ForestAdventureService: ForestAdventureServiceProtocol {

    private let forestManager: ForestDataManagerProtocol
    private let playerManager: PlayerDataManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let db = Firestore.firestore()
    
    init(forestManager: ForestDataManagerProtocol, playerManager: PlayerDataManagerProtocol, coreData: CoreDataManagerProtocol) {
        self.forestManager = forestManager
        self.playerManager = playerManager
        self.coreDataManager = coreData
    }
}

// MARK: - WEEKLY REWARDS

extension ForestAdventureService {
    
    func fetchWeeklyDailyRewards() async -> Resource<[WeeklyDailyCardModel]> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .error(error: ForestAdventureError.unauthenticated)
        }
        let trueNow = (try? await NetworkTimeHelper.getTrueTime()) ?? Date()
        let localForestRes = forestManager.fetchSafeForest(contextType: .main)
        if let forest = localForestRes.data {
            let dailyActivities = forest.dailyActivities
            let fixedTZStr = dailyActivities.fixedTimeZone ?? TimeZone.current.identifier
            var safeCalendar = Calendar.current
            safeCalendar.timeZone = TimeZone(identifier: fixedTZStr) ?? TimeZone(identifier: "UTC")!
            if let lastFetch = dailyActivities.lastFetchDate, safeCalendar.isDate(lastFetch, inSameDayAs: trueNow) {
                let currentDay = Int(dailyActivities.weeklyStreakCurrentDay)
                let lastClaim = dailyActivities.weeklyStreakLastClaimDate
                let cardList = generateCardList(currentDay: currentDay, lastClaimDate: lastClaim, trueNow: trueNow, calendar: safeCalendar)
                return .success(cardList)
            }
        }
        let docRef = db.collection(ForestSyncConstants.usersCollection).document(uid).collection(ForestSyncConstants.dailyRewardsCollection).document(ForestSyncConstants.metadataDocument)
        do {
            let document = try await docRef.getDocument()
            var currentDay = 0
            var lastClaimDate: Date? = nil
            var cloudTimeZone = TimeZone.current.identifier
            if document.exists, let data = document.data() {
                currentDay = data[ForestSyncConstants.weeklyStreakCurrentDayField] as? Int ?? 0
                lastClaimDate = (data[ForestSyncConstants.weeklyStreakLastClaimDateField] as? Timestamp)?.dateValue()
                cloudTimeZone = data[ForestSyncConstants.fixedTimeZoneField] as? String ?? TimeZone.current.identifier
            } else {
                let initialData: [String: Any] = [
                    ForestSyncConstants.weeklyStreakCurrentDayField: 0,
                    ForestSyncConstants.fixedTimeZoneField: cloudTimeZone,
                    ForestSyncConstants.firstVisitTimestamp: FieldValue.serverTimestamp()
                ]
                try await docRef.setData(initialData)
            }
            var safeCalendar = Calendar.current
            safeCalendar.timeZone = TimeZone(identifier: cloudTimeZone) ?? TimeZone(identifier: "UTC")!
            let context = coreDataManager.viewContext
            context.performAndWait {
                if let forest = forestManager.getCurrentForest(context: context), let dailyActivities = forest.dailyActivities {
                    dailyActivities.lastFetchDate = trueNow
                    dailyActivities.weeklyStreakCurrentDay = Int16(currentDay)
                    dailyActivities.weeklyStreakLastClaimDate = lastClaimDate
                    dailyActivities.fixedTimeZone = cloudTimeZone
                    coreDataManager.save(in: context)
                }
            }
            let cardList = generateCardList(currentDay: currentDay, lastClaimDate: lastClaimDate, trueNow: trueNow, calendar: safeCalendar)
            return .success(cardList)
        } catch {
            if let forest = localForestRes.data {
                let dailyActivities = forest.dailyActivities
                let fixedTZStr = dailyActivities.fixedTimeZone ?? TimeZone.current.identifier
                var safeCalendar = Calendar.current
                safeCalendar.timeZone = TimeZone(identifier: fixedTZStr) ?? TimeZone(identifier: "UTC")!
                let currentDay = Int(dailyActivities.weeklyStreakCurrentDay)
                let lastClaim = dailyActivities.weeklyStreakLastClaimDate
                let cardList = generateCardList(currentDay: currentDay, lastClaimDate: lastClaim, trueNow: trueNow, calendar: safeCalendar)
                return .success(cardList)
            }
            return .error(error: ForestAdventureError.networkError)
        }
    }
    
    func saveWeeklyReward(weeklyModel: WeeklyDailyCardModel, contextType: ForestDataManager.ContextType) async -> Resource<Bool> {
            guard let uid = Auth.auth().currentUser?.uid else {
                return .error(error: ForestAdventureError.unauthenticated)
            }
            
            let day = weeklyModel.day
            let localNow = Date()
            let context = contextType.context
            
            context.performAndWait {
                if let forest = forestManager.getCurrentForest(context: context), let dailyActivities = forest.dailyActivities {
                    dailyActivities.weeklyStreakCurrentDay = Int16(day)
                    dailyActivities.weeklyStreakLastClaimDate = localNow
                    dailyActivities.lastFetchDate = localNow
                    coreDataManager.save(in: context)
                }
            }
            let docRef = db.collection(ForestSyncConstants.usersCollection).document(uid).collection(ForestSyncConstants.dailyRewardsCollection).document(ForestSyncConstants.metadataDocument)
            
            docRef.setData([
                ForestSyncConstants.weeklyStreakCurrentDayField: day,
                ForestSyncConstants.weeklyStreakLastClaimDateField: FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error = error {
                    print("Background Firebase write error: \(error.localizedDescription)")
                }
            }
            return .success(true)
        }
}

// MARK: - DAILY SPIN REWARDS

extension ForestAdventureService {
    
    func fetchDailySpinStatusDate() async -> Resource<Date?> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .error(error: ForestAdventureError.unauthenticated)
        }
        do {
            let trueNow = try await NetworkTimeHelper.getTrueTime()
            let docRef = db.collection(ForestSyncConstants.usersCollection).document(uid).collection(ForestSyncConstants.dailyRewardsCollection).document(ForestSyncConstants.metadataDocument)
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data(), let lastUsed = (data[ForestSyncConstants.dailySpinLastUsedDateField] as? Timestamp)?.dateValue() {
                let targetTime = lastUsed.addingTimeInterval(86400)
                return .success(targetTime > trueNow ? targetTime : nil)
            }
            return .success(nil)
        } catch {
            let localForestRes = forestManager.fetchSafeForest(contextType: .main)
            if let forest = localForestRes.data, let lastUsed = forest.dailyActivities.dailySpinLastUsedDate {
                let localNow = Date()
                let targetTime = lastUsed.addingTimeInterval(86400)
                return .success(targetTime > localNow ? targetTime : nil)
            }
            return .success(nil)
        }
    }
    
    func claimDailySpinReward(reward: QuestRewardModel, contextType: ForestDataManager.ContextType) async -> Resource<Bool> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .error(error: ForestAdventureError.unauthenticated)
        }
        _ = forestManager.claimReward(model: reward, contextType: contextType)
        let context = contextType.context
        context.performAndWait {
            if let forest = forestManager.getCurrentForest(context: context), let dailyActivities = forest.dailyActivities {
                dailyActivities.dailySpinLastUsedDate = Date()
                coreDataManager.save(in: context)
            }
        }
        let docRef = db.collection(ForestSyncConstants.usersCollection).document(uid).collection(ForestSyncConstants.dailyRewardsCollection).document(ForestSyncConstants.metadataDocument)
        docRef.setData([
            ForestSyncConstants.dailySpinLastUsedDateField: FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Background Firebase write error: \(error.localizedDescription)")
            }
        }
        return .success(true)
    }
}

// MARK: - PRIVATE HELPERS

private extension ForestAdventureService {
    
    func generateCardList(currentDay: Int, lastClaimDate: Date?, trueNow: Date, calendar: Calendar) -> [WeeklyDailyCardModel] {
        var list: [WeeklyDailyCardModel] = []
        var activeDay = 1
        var isClaimedToday = false
        if let claimDate = lastClaimDate {
            if calendar.isDate(claimDate, inSameDayAs: trueNow) {
                activeDay = currentDay
                isClaimedToday = true
            } else if calendar.isDate(claimDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: trueNow)!) {
                activeDay = (currentDay >= 7) ? 1 : (currentDay + 1)
            } else {
                activeDay = 1
            }
        }
        let baseRewards: [LocalRewardModel] = [
            .standart(model: .gold(count: 100)),
            .standart(model: .water(count: 50)),
            .chest(model: .antique),
            .standart(model: .gold(count: 200)),
            .chest(model: .gold),
            .standart(model: .diamond(count: 10)),
            .chest(model: .gold)
        ]
        for dayIndex in 1...7 {
            let status: BountyStatus
            if dayIndex < activeDay {
                status = .claimed
            } else if dayIndex == activeDay {
                status = isClaimedToday ? .claimed : .ready
            } else {
                status = .locked
            }
            list.append(WeeklyDailyCardModel(day: dayIndex, bounty: baseRewards[dayIndex - 1], status: status))
        }
        return list
    }
}
