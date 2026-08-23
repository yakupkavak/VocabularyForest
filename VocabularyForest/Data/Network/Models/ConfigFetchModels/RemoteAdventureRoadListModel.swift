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
    let theme: RemoteAdventureRoadThemeModel?
    let items: [RemoteAdventureRoadModel]?
}

struct RemoteAdventureRoadThemeModel: Decodable {
    let backgroundTopColor: String?
    let backgroundBottomColor: String?
    let titleTextColor: String?
    let subtitleTextColor: String?
    let countdownTextColor: String?
    let countdownBackgroundColor: String?
    let wordLabelTextColor: String?
    let shortBadgeTopColor: String?
    let shortBadgeBottomColor: String?
    let shortBadgeTextColor: String?
    let longBadgeTopColor: String?
    let longBadgeBottomColor: String?
    let longBadgeTextColor: String?
}

struct RemoteAdventureRoadModel: Decodable {
    let id: String?
    let wordCount: Int?
    let shortTermReward, longTermReward: RemoteRewardModel?
}
