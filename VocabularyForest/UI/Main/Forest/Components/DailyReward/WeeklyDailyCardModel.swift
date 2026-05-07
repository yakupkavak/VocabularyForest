//
//  DailyCardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.03.2026.
//

struct WeeklyDailyCardModel {
    var day: Int
    var bounty: LocalRewardModel
    var presentation: RewardPresentationModel?
    var status: BountyStatus
}
