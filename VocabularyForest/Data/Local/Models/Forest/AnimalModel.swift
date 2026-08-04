//
//  AnimalModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import Foundation

struct AnimalModel: Equatable, ComponentNameable, ComponentModelProtocol {
    let id: UUID
    let type: ComponentType = .animal
    let assetName: String
    let createdDate: Date
    var characterName: String
    var assetSource: ImageSourceType
    var poster: RewardAssetReference
    var healthValue: Int
    var isAlive: Bool
    var xPosition: CGFloat
    var yPosition: CGFloat
    var lastUpdatedDate: Date
    /// Reward catalog id (rewards_config) used to re-download remote assets after a cloud restore.
    var rewardId: String? = nil
    /// Invariant: an entity with `assetSource == .offlineStorage` and `assetReady == true`
    /// has its file verified on disk. Only such entities are added to the scene.
    var assetReady: Bool = true
}

