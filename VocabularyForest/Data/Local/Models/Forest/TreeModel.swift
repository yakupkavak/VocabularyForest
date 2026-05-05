//
//  TreeModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import Foundation

struct TreeModel: Equatable, ComponentNameable, ComponentModelProtocol{
    var id: UUID
    var type: ComponentType = .plant
    let assetName: String
    var characterName: String
    let isAlive: Bool
    let createdDate: Date
    let treeHealthValue: Int
    var xPosition: CGFloat
    var yPosition: CGFloat
    var lastUpdatedDate: Date
}

protocol ComponentModelProtocol {
    var id: UUID { get }
    var assetName: String { get }
    var createdDate: Date { get }
    var xPosition: CGFloat { get set }
    var yPosition: CGFloat { get set }
    var type: ComponentType { get }
    var lastUpdatedDate: Date { get }
}
