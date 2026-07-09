//
//  RemoteAdventureRoadListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

import Foundation

struct RemoteAdventureRoadListModel: Decodable {
    let id: String?
    let title: RemoteLocalizedText?
    let description: RemoteLocalizedText?
    let seasonEndDateString: String?
    let items: [RemoteAdventureRoadModel]?
}

struct RemoteAdventureRoadModel: Decodable {
    let id: String?
    let wordCount: Int?
    let shortTermReward, longTermReward: RemoteRewardModel?
}
