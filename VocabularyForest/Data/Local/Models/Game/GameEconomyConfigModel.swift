//
//  GameEconomyConfigModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.04.2026.
//

import Foundation

struct GameEconomyConfigModel: Decodable {
    let id: String?
    let season: String?
    let killCap: GameKillCapModel?
    let progressionTargets: GameProgressionTargetsModel?
}

struct GameKillCapModel: Decodable {
    let minGoldPerKill: Int?
    let maxGoldPerKill: Int?
    let dailyKillCountCap: Int?
}

struct GameProgressionTargetsModel: Decodable {
    let dailyActiveGoldTarget: Int?
    let rainCost: Int?
    let rainDecayPerHour: Int?
    let dailyQuestCompletionRateForRain: Double?
}
