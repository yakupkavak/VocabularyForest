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
    /// IAP bundles ("Hazır Paketler"); absent on configs without in-app purchases
    let packages: RemotePackagesSectionModel?
}

struct RemotePackagesSectionModel: Decodable {
    let id: String?
    let title: RemoteLocalizedText?
    let items: [RemotePackageModel]?
}

struct RemotePackageModel: Decodable {
    let id: String?
    /// App Store Connect product identifier of the consumable IAP
    let productId: String?
    let displayName: RemoteLocalizedText?
    /// Rewards granted on purchase; reuses the shared reward schema
    let contents: [RemoteRewardModel]?
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
    /// Max purchases per ISO week; nil means unlimited
    let weeklyPurchaseLimit: Int?
}

struct RemoteMarketPriceModel: Decodable {
    let currency: String?
    let amount: Int?
}
