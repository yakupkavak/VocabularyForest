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
    let chestOdds: GameChestOddsModel?
    let chestRewardRanges: GameChestRewardRangesModel?
    let killCap: GameKillCapModel?
}

struct GameChestOddsModel: Decodable {
    let goldChestDiamondChance: Int?
    let goldChestWaterChance: Int?
    let natureChestAnimalChance: Int?
    let antiqueChestAnimalChance: Int?
}

struct GameKillCapModel: Decodable {
    let minGoldPerKill: Int?
    let maxGoldPerKill: Int?
    let dailyKillCountCap: Int?
}

struct GameChestRewardRangesModel: Decodable {
    let goldChestGoldMin: Int?
    let goldChestGoldMax: Int?
    let goldChestDiamondMin: Int?
    let goldChestDiamondMax: Int?
    let diamondChestDiamondMin: Int?
    let diamondChestDiamondMax: Int?
}
