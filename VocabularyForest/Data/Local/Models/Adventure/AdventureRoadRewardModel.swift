//
//  AdventureRoadRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct AdventureRoadRewardModel {
    let wordCount: Int
    let shortTermReward: LocalRewardModel
    let longTermReward: LocalRewardModel
}

struct AdventureRoadConfigModel {
    let id: String?
    let title: String?
    let description: String?
    let seasonEndDate: Date
    let rewards: [AdventureRoadRewardModel]
}
