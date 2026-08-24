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
    /// Render size as a fraction of screen height (rewards_config); nil falls back
    /// to the category default and the texture aspect ratio.
    var widthRatio: CGFloat? = nil
    var heightRatio: CGFloat? = nil
}
