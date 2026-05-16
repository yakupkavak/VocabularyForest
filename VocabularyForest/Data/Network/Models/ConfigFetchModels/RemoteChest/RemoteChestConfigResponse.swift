//
//  RemoteChestConfigResponse.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.05.2026.
//

struct RemoteChestConfigResponse: Decodable {
    let id: String
    let season: String
    let chests: [RemoteChestModel]
    let pools: [String: [RemoteRewardItem]]
    let specificItems: [String: RemoteRewardItem]
}
