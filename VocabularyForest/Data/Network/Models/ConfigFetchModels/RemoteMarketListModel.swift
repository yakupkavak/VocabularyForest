//
//  RemoteMarketListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.07.2026.
//

import Foundation

struct RemoteMarketListModel: Decodable {
    let id: String?
    let title: RemoteLocalizedText?
    let sections: [RemoteMarketSectionModel]?
}

struct RemoteMarketSectionModel: Decodable {
    let id: String?
    let title: RemoteLocalizedText?
    let items: [RemoteMarketItemModel]?
}

struct RemoteMarketItemModel: Decodable {
    let id: String?
    let price: RemoteMarketPriceModel?
    let reward: RemoteRewardModel?
}

struct RemoteMarketPriceModel: Decodable {
    let currency: String?
    let amount: Int?
}
