//
//  AnimalModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import Foundation

struct AnimalModel: Equatable {
    let id: UUID
    let name: String
    let assetName: String
    let createdDate: Date
    let healthValue: Int
    let isAlive: Bool
    let xPosition: CGFloat
    let yPosition: CGFloat
}

