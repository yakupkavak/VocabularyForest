//
//  WeeklyRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct WeeklyRewardModel: Encodable {
    let id: UUID
    let day: Int
    let reward: LocalRewardModel
    let presentation: RewardPresentationModel?
}
