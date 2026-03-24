//
//  SafeForestModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 31.01.2026.
//

import Foundation

struct SafeForestModel: Sendable {
    let rainValue: Int
    let moneyValue: Int
    let diamondValue: Int
    let landHealthPercent: Int
    let landStatus: Bool
    let isRaining: Bool
    let lastRainUpdateDate: Date?
    let lastDailyResetDate: Date?
    let lastWeeklyResetDate: Date?
    let lastMonthlyResetDate: Date?
    let quests: [QuestModel]
    let sculptures: [SculptureModel]
    let trees: [TreeModel]
    let animals: [AnimalModel]
}
