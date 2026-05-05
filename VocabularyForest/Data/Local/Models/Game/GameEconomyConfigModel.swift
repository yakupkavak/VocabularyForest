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
