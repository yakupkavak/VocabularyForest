//
//  TreeModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.11.2025.
//

import Foundation

struct TreeModel {
    let id: UUID
    let treeName: String
    let isAlive: Bool
    let createdDate: Date
    let treeHealthValue: Int
    let treeXPosition: CGFloat
    let treeYPosition: CGFloat
}
