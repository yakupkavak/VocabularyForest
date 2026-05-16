//
//  AdventureRoadRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation

struct AdventureRoadRewardModel: Encodable {
    let wordCount: Int
    let shortTermReward: LocalRewardType
    let longTermReward: LocalRewardType
}

struct AdventureRoadConfigModel {
    let id: String?
    let seasonEndDate: Date
    let rewards: [AdventureRoadRewardModel]
}
