//
//  MockLocalRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.06.2026.
//

@testable import VocabularyForest

extension LocalRewardModel {
    static func mock(rewardCount: Int = 1, reward: LocalRewardType = .standart(model: LocalQuestRewardModel.mock())) -> LocalRewardModel {
        LocalRewardModel(rewardCount: rewardCount, reward: reward)
    }
}
