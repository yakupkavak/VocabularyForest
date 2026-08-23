//
//  RemoteDailySpinListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

struct RemoteDailySpinListModel: Decodable {
    let id: String?
    let items: [RemoteDailySpinModel]?
}

struct RemoteDailySpinModel: Decodable {
    let id: Int?
    let weight: Double?
    let textColorHex: String?
    let backgroundHexes: [String]?
    let text: RemoteLocalizedText?
    let reward: RemoteRewardModel?
}
