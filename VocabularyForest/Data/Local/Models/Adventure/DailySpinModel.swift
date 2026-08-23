//
//  DailySpinModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct DailySpinModel {
    let id: Int
    let weight: Double
    let reward: LocalRewardModel
    let textColorHex: String?
    let backgroundHexes: [String]?
}
