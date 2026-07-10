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
}

enum ChestStatus {
    case open
    case close
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
