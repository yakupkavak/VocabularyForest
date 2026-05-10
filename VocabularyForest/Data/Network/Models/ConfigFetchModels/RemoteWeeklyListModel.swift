//
//  RemoteWeeklyListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

struct RemoteWeeklyListModel: Decodable {
    let id: String?
    let seasonEndDateString: String?
    let items: [RemoteWeeklyRewardModel]
}

struct RemoteWeeklyRewardModel: Decodable {
    let id: String?
    let day: Int?
    let reward: RemoteRewardModel?
}
