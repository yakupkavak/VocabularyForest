//
//  ReadyRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.06.2026.
//


/// If the resource downloaded successfully, then we will import core data via this struct.
struct ReadyRewardModel {
    let id: String
    let category: QuestRewardModel
    let rewardCount: Int
    let displayName: RemoteLocalizedText
    let assetSource: RewardAssetReference
    let posterImage: RewardAssetReference
}
