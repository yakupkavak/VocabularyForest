//
//  TreeModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import Foundation

struct TreeModel: Equatable, ComponentNameable, ComponentModelProtocol{
    let id: UUID
    let assetName: String
    var characterName: String = ""
    let isAlive: Bool
    let createdDate: Date
    let treeHealthValue: Int
    var xPosition: CGFloat
    var yPosition: CGFloat
}

protocol ComponentModelProtocol {
    var assetName: String { get }
    var createdDate: Date { get }
    var xPosition: CGFloat { get set }
    var yPosition: CGFloat { get set }
}
