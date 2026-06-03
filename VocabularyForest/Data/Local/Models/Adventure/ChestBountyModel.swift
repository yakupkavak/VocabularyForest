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
