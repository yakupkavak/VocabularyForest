//
//  RemoteChestDrops.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.05.2026.
//

struct RemoteChestEconomy: Decodable {
    let guaranteedDrops: [RemoteLootDrop]?
    let randomDrops: [RemoteLootDrop]?
}

struct RemoteLootDrop: Decodable {
    let dropType: String?
    let itemId: String?
    let dropChance: Int?
    let minAmount: Int?
    let maxAmount: Int?
}

struct RemoteRewardItem: Decodable {
    let id: String?
    let category: String?
    let posterPath: String?
    let downloadPath: String?
    let probabilityWeight: Double?
    let displayName: RemoteLocalizedText?
}
