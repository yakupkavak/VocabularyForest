//
//  ChestBountyModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct LocalChestModel: Hashable {
    let id: String
    let version: Int
    let displayName: RemoteLocalizedText
    let closeLocalImagePath: RewardAssetReference
    let openLocalImagePath: RewardAssetReference
    let textHexColor: String?
    let backgroundGradientColors: [String]?
    let roadColorHex: String?
    let cardGradientHexes: [String]?
    let cardTextColorHex: String?
    /// Guaranteed S/S+ drop configuration; nil for chests without pity
    let pity: LocalChestPityModel?

    init(
        id: String,
        version: Int,
        displayName: RemoteLocalizedText,
        closeLocalImagePath: RewardAssetReference,
        openLocalImagePath: RewardAssetReference,
        textHexColor: String?,
        backgroundGradientColors: [String]?,
        roadColorHex: String? = nil,
        cardGradientHexes: [String]? = nil,
        cardTextColorHex: String? = nil,
        pity: LocalChestPityModel? = nil
    ) {
        self.id = id
        self.version = version
        self.displayName = displayName
        self.closeLocalImagePath = closeLocalImagePath
        self.openLocalImagePath = openLocalImagePath
        self.textHexColor = textHexColor
        self.backgroundGradientColors = backgroundGradientColors
        self.roadColorHex = roadColorHex
        self.cardGradientHexes = cardGradientHexes
        self.cardTextColorHex = cardTextColorHex
        self.pity = pity
    }
}

enum ChestStatus {
    case open
    case close
}

/// Rewards guaranteed by the pity system at a fixed open count,
/// surfaced at the top of the chest info popup
struct ChestPityInfoModel: Hashable {
    let tier: RewardTier
    let threshold: Int
    let rewards: [LocalRewardModel]
}

/// Everything the chest info popup renders: possible drops plus pity guarantees
struct ChestInfoModel: Hashable {
    let drops: [ChestDropInfoModel]
    let pityGuarantees: [ChestPityInfoModel]
}

/// A single possible drop of a chest, used to inform the user before purchase
struct ChestDropInfoModel: Identifiable, Hashable {
    let id: String
    let reward: LocalRewardModel
    /// nil means the drop is guaranteed
    let chancePercent: Int?
    let minAmount: Int
    let maxAmount: Int
    
    var amountText: String {
        minAmount == maxAmount ? "x\(minAmount)" : "x\(minAmount)-\(maxAmount)"
    }
}
