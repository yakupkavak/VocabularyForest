//
//  TreeModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import Foundation

struct TreeModel: Equatable, ComponentNameable, ComponentModelProtocol {
    let id: UUID
    let type: ComponentType = .plant
    let assetName: String
    let createdDate: Date
    var characterName: String
    var assetSource: ImageSourceType
    var poster: RewardAssetReference
    var isAlive: Bool
    var treeHealthValue: Int
    var xPosition: CGFloat
    var yPosition: CGFloat
    var lastUpdatedDate: Date
    /// Reward catalog id (rewards_config) used to re-download remote assets after a cloud restore.
    var rewardId: String? = nil
    /// Invariant: an entity with `assetSource == .offlineStorage` and `assetReady == true`
    /// has its file verified on disk. Only such entities are added to the scene.
    var assetReady: Bool = true
}

protocol ComponentModelProtocol {
    var id: UUID { get }
    var assetName: String { get }
    var createdDate: Date { get }
    var xPosition: CGFloat { get set }
    var yPosition: CGFloat { get set }
    var type: ComponentType { get }
    var lastUpdatedDate: Date { get }
    var assetSource: ImageSourceType { get }
    var poster: RewardAssetReference { get }
}
