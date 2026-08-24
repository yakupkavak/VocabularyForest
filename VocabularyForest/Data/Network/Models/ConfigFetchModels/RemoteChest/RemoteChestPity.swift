//
//  RemoteChestPity.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

/// Pity (guaranteed drop) configuration of a chest, mirroring the `pity`
/// object in `chest_rewards_config`. Chests sharing a `counterGroup`
/// (e.g. gold + diamond → "general") advance the same open counter.
struct RemoteChestPity: Decodable {
    let counterGroup: String?
    let sTier: RemoteChestPityTier?
    let sPlusTier: RemoteChestPityTier?
    /// Percent chance (0-100) of a bonus S drop on every regular open
    let naturalDropChanceS: Int?
    /// Percent chance (0-100) of a bonus S+ drop on every regular open
    let naturalDropChanceSPlus: Int?
}

struct RemoteChestPityTier: Decodable {
    let threshold: Int?
    /// Reward ids resolved against the rewards catalog (`rewards_config`)
    let pool: [String]?
}
