//
//  RemoteDailySpinListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

struct RemoteDailySpinListModel: Decodable {
    let id: String?
    let seasonEndDateString: String?
    let items: [RemoteDailySpinModel]
}

struct RemoteDailySpinModel: Decodable {
    let id: String?
    let weight: Double?
    let reward: RemoteRewardModel?
}
