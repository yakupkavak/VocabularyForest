//
//  ChestRewardsConfigModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import Foundation

struct ChestRewardsConfigModel: Codable {
    let id: String?
    let season: String?
    let odds: ChestRewardOddsModel
    let ranges: ChestRewardRangesModel
    let pools: ChestRewardPoolsModel
    let visuals: [ChestVisualModel]
}

struct ChestRewardOddsModel: Codable {
    let goldChestDiamondChance: Int
    let goldChestWaterChance: Int
    let natureChestAnimalChance: Int
    let antiqueChestAnimalChance: Int
}

struct ChestRewardRangesModel: Codable {
    let goldChestGoldMin: Int
    let goldChestGoldMax: Int
    let goldChestDiamondMin: Int
    let goldChestDiamondMax: Int
    let goldChestWaterMin: Int
    let goldChestWaterMax: Int
    let diamondChestDiamondMin: Int
    let diamondChestDiamondMax: Int
}

struct ChestRewardPoolsModel: Codable {
    let natureAnimals: [ChestRewardCandidateModel]
    let naturePlants: [ChestRewardCandidateModel]
    let antiqueAnimals: [ChestRewardCandidateModel]
    let antiqueSculptures: [ChestRewardCandidateModel]
}

struct ChestRewardCandidateModel: Codable {
    let id: String
    let category: String
    let modelKey: String
    let probabilityWeight: Double
    let descriptor: RewardMediaDescriptor

    var safeProbabilityWeight: Double {
        max(probabilityWeight, 0.0001)
    }
}

struct ChestVisualModel: Codable {
    let id: String
    let chestType: String
    let closedImagePath: String
    let openImagePath: String
}
