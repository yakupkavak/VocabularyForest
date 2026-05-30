//
//  AnimalModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import Foundation

struct AnimalModel: Equatable, ComponentNameable, ComponentModelProtocol {
    var id: UUID
    var type: ComponentType = .animal
    var characterName: String
    var assetSource: ImageSourceType
    var poster: RewardAssetReference
    let assetName: String
    let createdDate: Date
    let healthValue: Int
    let isAlive: Bool
    var xPosition: CGFloat
    var yPosition: CGFloat
    var lastUpdatedDate: Date

}

