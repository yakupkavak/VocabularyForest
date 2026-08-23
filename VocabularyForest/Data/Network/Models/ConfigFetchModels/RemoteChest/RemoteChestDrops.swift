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
    let reward: RemoteRewardModel?
    let dropChance: Int?
    let minAmount: Int?
    let maxAmount: Int?
}
