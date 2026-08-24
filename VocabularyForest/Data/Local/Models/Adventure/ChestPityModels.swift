//
//  ChestPityModels.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import Foundation

/// Validated pity configuration carried on a `LocalChestModel`.
struct LocalChestPityModel: Hashable {
    let counterGroup: String
    let sTier: LocalChestPityTierModel
    let sPlusTier: LocalChestPityTierModel
    /// Percent chance (0-100) of a bonus S drop on every regular open
    let naturalDropChanceS: Int
    /// Percent chance (0-100) of a bonus S+ drop on every regular open
    let naturalDropChanceSPlus: Int
}

struct LocalChestPityTierModel: Hashable {
    let threshold: Int
    let pool: [String]
}

/// Snapshot of a pity counter for UI (chest card progress bar).
struct ChestPityProgressModel: Hashable {
    let openCount: Int
    let sThreshold: Int
    let sPlusThreshold: Int

    /// Opens completed inside the current S cycle (0..<sThreshold)
    var sCycleCount: Int {
        openCount % sThreshold
    }

    /// Opens completed inside the current S+ cycle (0..<sPlusThreshold)
    var sPlusCycleCount: Int {
        openCount % sPlusThreshold
    }

    /// The next guaranteed milestone is an S+ when the S+ cycle is closer to
    /// completion than a full S cycle away; the card highlights that state.
    var isNextGuaranteeSPlus: Bool {
        sPlusThreshold - sPlusCycleCount <= sThreshold - sCycleCount
    }

    var remainingOpensToNextGuarantee: Int {
        min(sThreshold - sCycleCount, sPlusThreshold - sPlusCycleCount)
    }
}

/// Result of registering one chest open against the pity system.
struct ChestPityDropDecision: Hashable {
    /// Tier granted because the counter reached a threshold (nil when none)
    let guaranteedTier: RewardTier?
    /// Tier granted by the per-open natural chance roll (nil when none)
    let naturalTier: RewardTier?
}
