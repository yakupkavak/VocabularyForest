//
//  SafeChestConfigModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import Foundation

struct SafeChestConfigModel {
    let configID: String?
    let season: String?
    let goldChestDiamondChance: Int
    let goldChestWaterChance: Int
    let natureChestAnimalChance: Int
    let antiqueChestAnimalChance: Int
    let goldChestGoldMin: Int
    let goldChestGoldMax: Int
    let goldChestDiamondMin: Int
    let goldChestDiamondMax: Int
    let goldChestWaterMin: Int
    let goldChestWaterMax: Int
    let diamondChestDiamondMin: Int
    let diamondChestDiamondMax: Int
    let lastUpdatedDate: Date
}

struct SafeChestRewardItemModel {
    let id: String
    let chestType: String
    let rewardCategory: String
    let modelKey: String
    let probabilityWeight: Double
    let mediaSourceType: String
    let mediaFileType: String
    let previewImageURL: String?
    let sourceFieldKey: String?
    let sourceVersion: String?
    let lastUpdatedDate: Date
}

struct SafeChestVisualItemModel {
    let id: String
    let chestType: String
    let closedImagePath: String
    let openImagePath: String
    let lastUpdatedDate: Date
}
