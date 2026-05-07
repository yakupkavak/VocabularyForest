//
//  DailySpinModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct DailySpinModel: Encodable {
    let weight: Double
    let reward: LocalRewardModel
    let presentation: RewardPresentationModel?
}
