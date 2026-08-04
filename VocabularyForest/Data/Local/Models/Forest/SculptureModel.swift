//
//  SculptureModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import Foundation

struct SculptureModel: Equatable, ComponentNameable, ComponentModelProtocol {
    let id: UUID
    let type: ComponentType = .sculpture
    let assetName: String
    let createdDate: Date
    var characterName: String
    var assetSource: ImageSourceType
    var poster: RewardAssetReference
    var xPosition: CGFloat
    var yPosition: CGFloat
    var lastUpdatedDate: Date
    /// Reward catalog id (rewards_config) used to re-download remote assets after a cloud restore.
    var rewardId: String? = nil
    /// Invariant: an entity with `assetSource == .offlineStorage` and `assetReady == true`
    /// has its file verified on disk. Only such entities are added to the scene.
    var assetReady: Bool = true
}

let baseSculptureList = [
    SculptureModel(
        id: UUID(),
        assetName: "water_statue",
        createdDate: Date(),
        characterName: String(localized: "Peace"),
        assetSource: .appAssets,
        poster: RewardAssetReference(key: "water_statue", source: .appAssets),
        xPosition: 0.15,
        yPosition: 0.4,
        lastUpdatedDate: Date()
    ),
    SculptureModel(
        id: UUID(),
        assetName: "grass_statue",
        createdDate: Date(),
        characterName: String(localized: "happiness"),
        assetSource: .appAssets,
        poster: RewardAssetReference(key: "grass_statue", source: .appAssets),
        xPosition: 0.03,
        yPosition: 0.23,
        lastUpdatedDate: Date()
    )
]
