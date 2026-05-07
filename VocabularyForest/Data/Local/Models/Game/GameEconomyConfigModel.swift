//
//  GameEconomyConfigModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.04.2026.
//

import Foundation

struct GameEconomyConfigModel {
    let id: String?
    let season: String?
    let chestOdds: GameChestOddsModel
    let chestRewardRanges: GameChestRewardRangesModel
    let killCap: GameKillCapModel
    let marketPrices: GameMarketPricesModel
    let progressionTargets: GameProgressionTargetsModel
}

struct GameChestOddsModel {
    let goldChestDiamondChance: Int
    let goldChestWaterChance: Int
    let natureChestAnimalChance: Int
    let antiqueChestAnimalChance: Int
}

struct GameKillCapModel {
    let minGoldPerKill: Int
    let maxGoldPerKill: Int
    let dailyKillCountCap: Int
}

struct GameChestRewardRangesModel {
    let goldChestGoldMin: Int
    let goldChestGoldMax: Int
    let goldChestDiamondMin: Int
    let goldChestDiamondMax: Int
    let diamondChestDiamondMin: Int
    let diamondChestDiamondMax: Int
}

struct GameMarketPricesModel {
    let animalGold: Int
    let plantGoldMin: Int
    let plantGoldMax: Int
    let sculptureGold: Int
}

struct GameProgressionTargetsModel {
    let hourlyGoldTarget: Int
    let adventureRoadTotalGoldTarget: Int
    let rainCost: Int
    let rainDecayPerHour: Int
    let dailyQuestCompletionRateForRain: Double
}
