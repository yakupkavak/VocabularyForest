//
//  SafeForestModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 31.01.2026.
//

import Foundation

struct SafeForestModel: Sendable {
    let forestId: UUID
    let ownerId: String?
    let rainValue: Int
    let moneyValue: Int
    let diamondValue: Int
    let landHealthPercent: Int
    /// Chest pity open counters, synced on the main forest document like the balances
    let pityNatureOpenCount: Int
    let pityAntiqueOpenCount: Int
    let pityGeneralOpenCount: Int
    let landStatus: Bool
    let isRaining: Bool
    let lastRainUpdateDate: Date?
    let lastDailyResetDate: Date?
    let lastWeeklyResetDate: Date?
    let lastMonthlyResetDate: Date?
    let quests: [QuestTrackModel]
    let sculptures: [SculptureModel]
    let trees: [TreeModel]
    let animals: [AnimalModel]
    let player: PlayerModel
    let lastUpdatedDate: Date
    let lastSyncCloudTime: Date?
    let dailyActivities: DailyActivitiesModel
}
