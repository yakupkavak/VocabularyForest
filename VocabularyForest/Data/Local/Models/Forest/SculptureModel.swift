//
//  SculptureModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import Foundation

struct SculptureModel: Equatable, ComponentNameable, ComponentModelProtocol {
    var id: UUID
    var type: ComponentType = .sculpture
    var assetSource: ImageSourceType
    var poster: RewardAssetReference
    let assetName: String
    var characterName: String
    let createdDate: Date
    var xPosition: CGFloat
    var yPosition: CGFloat
    var lastUpdatedDate: Date
}

let baseSculptureList = [
    SculptureModel(id: UUID(),assetSource: .appAssets, poster: RewardAssetReference(key: "water_statue", source: .appAssets), assetName: "water_statue", characterName: String(localized: "Peace"), createdDate: Date(), xPosition: 0.15, yPosition: 0.4, lastUpdatedDate: Date()),
    SculptureModel(id: UUID(),assetSource: .appAssets, poster: RewardAssetReference(key: "grass_statue", source: .appAssets), assetName: "grass_statue", characterName: String(localized: "happiness"), createdDate: Date(), xPosition: 0.03, yPosition: 0.23, lastUpdatedDate: Date())
]
