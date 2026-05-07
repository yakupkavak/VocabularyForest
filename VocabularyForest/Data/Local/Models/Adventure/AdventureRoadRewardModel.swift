//
//  AdventureRoadRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct AdventureRoadRewardModel: Encodable {
    let wordCount: Int
    let shortTermReward: LocalRewardModel
    let shortTermPresentation: RewardPresentationModel?
    let longTermReward: LocalRewardModel
    let longTermPresentation: RewardPresentationModel?
}

struct AdventureRoadConfigModel {
    let id: String?
    let title: String
    let seasonEndDate: Date
    let rewards: [AdventureRoadRewardModel]
}
