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
    let assetName: String
    var characterName: String = ""
    let createdDate: Date
    var xPosition: CGFloat
    var yPosition: CGFloat
}

let baseSculptureList = [
    SculptureModel(id: UUID(), assetName: "water_statue", createdDate: Date(), xPosition: 0.15, yPosition: 0.4),
    SculptureModel(id: UUID(), assetName: "grass_statue", createdDate: Date(), xPosition: 0.03, yPosition: 0.23)
]
