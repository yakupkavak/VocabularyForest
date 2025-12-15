//
//  SculptureModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.11.2025.
//

import Foundation

struct SculptureModel: Equatable {
    let name: String
    let createDate: Date
    let xPosition: CGFloat
    let yPosition: CGFloat
}

let baseSculptureList = [
    SculptureModel(name: "water_statue", createDate: Date(), xPosition: 0.10, yPosition: 0.4),
    SculptureModel(name: "grass_statue", createDate: Date(), xPosition: 0.03, yPosition: 0.2)
]
