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
    let name: String
    var characterName: String = ""
    let assetName: String
    let createdDate: Date
    let healthValue: Int
    let isAlive: Bool
    var xPosition: CGFloat
    var yPosition: CGFloat
}

