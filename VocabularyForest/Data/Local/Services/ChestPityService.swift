//
//  ChestPityService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import Foundation

protocol RandomRollerProtocol: AnyObject {
    func roll(in range: ClosedRange<Int>) -> Int
}

final class SystemRandomRoller: RandomRollerProtocol {
    func roll(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range)
    }
}

protocol ChestPityCounterStoreProtocol: AnyObject {
    func openCount(group: String) -> Int
    func setOpenCount(_ count: Int, group: String)
}

protocol ChestPityServiceProtocol: AnyObject {
    func progress(for pity: LocalChestPityModel) -> ChestPityProgressModel
    /// Advances the counter for one chest open and reports which bonus tiers
    /// (if any) must be granted on top of the regular drops.
    func registerOpen(pity: LocalChestPityModel) -> ChestPityDropDecision
    /// Picks a reward id from the pool matching the granted tier.
    func poolRewardId(for tier: RewardTier, pity: LocalChestPityModel) -> String?
}

// MARK: - COUNTER STORE

// MARK: - CONSTANTS

private extension ChestPityCounterStore {
    enum Constants {
        static let keyPrefix = "chest_pity.open_count."
    }
}

final class ChestPityCounterStore {

    // MARK: - PROPERTIES

    private let defaults: UserDefaults

    // MARK: - INIT

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ChestPityCounterStore: ChestPityCounterStoreProtocol {
    func openCount(group: String) -> Int {
        defaults.integer(forKey: Constants.keyPrefix + group)
    }

    func setOpenCount(_ count: Int, group: String) {
        defaults.set(count, forKey: Constants.keyPrefix + group)
    }
}

// MARK: - FOREST COUNTER STORE

/// Persists pity counters on the Forest entity so they ride the regular
/// forest cloud sync (same LWW flow as the gold/diamond balances). Counter
/// groups the config may introduce before the client knows them fall back
/// to the local-only UserDefaults store.
final class ForestChestPityCounterStore {

    // MARK: - PROPERTIES

    private let forestManager: ForestDataManagerProtocol
    private let fallbackStore: ChestPityCounterStoreProtocol

    // MARK: - INIT

    init(forestManager: ForestDataManagerProtocol, fallbackStore: ChestPityCounterStoreProtocol) {
        self.forestManager = forestManager
        self.fallbackStore = fallbackStore
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ForestChestPityCounterStore: ChestPityCounterStoreProtocol {
    func openCount(group: String) -> Int {
        guard let counter = ChestPityCounterField(rawValue: group) else {
            return fallbackStore.openCount(group: group)
        }
        return forestManager.fetchPityOpenCount(counter: counter, contextType: .background)
    }

    func setOpenCount(_ count: Int, group: String) {
        guard let counter = ChestPityCounterField(rawValue: group) else {
            fallbackStore.setOpenCount(count, group: group)
            return
        }
        _ = forestManager.updatePityOpenCount(counter: counter, value: count, contextType: .background)
    }
}

// MARK: - PITY SERVICE

// MARK: - CONSTANTS

private extension ChestPityService {
    enum Constants {
        static let percentRange: ClosedRange<Int> = 1...100
    }
}

final class ChestPityService {

    // MARK: - PROPERTIES

    private let counterStore: ChestPityCounterStoreProtocol
    private let randomRoller: RandomRollerProtocol

    // MARK: - INIT

    init(counterStore: ChestPityCounterStoreProtocol, randomRoller: RandomRollerProtocol) {
        self.counterStore = counterStore
        self.randomRoller = randomRoller
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ChestPityService: ChestPityServiceProtocol {
    func progress(for pity: LocalChestPityModel) -> ChestPityProgressModel {
        ChestPityProgressModel(
            openCount: counterStore.openCount(group: pity.counterGroup),
            sThreshold: pity.sTier.threshold,
            sPlusThreshold: pity.sPlusTier.threshold
        )
    }

    func registerOpen(pity: LocalChestPityModel) -> ChestPityDropDecision {
        let newCount = counterStore.openCount(group: pity.counterGroup) + 1
        counterStore.setOpenCount(newCount, group: pity.counterGroup)

        // The S+ milestone replaces the S milestone it coincides with (50 = 5x10),
        // and counters never reset so the cycle repeats (60 → S, 100 → S+ …).
        var guaranteedTier: RewardTier?
        if newCount.isMultiple(of: pity.sPlusTier.threshold) {
            guaranteedTier = .sPlus
        } else if newCount.isMultiple(of: pity.sTier.threshold) {
            guaranteedTier = .s
        }

        // A single percent roll keeps S+ and S chances exclusive and exact.
        var naturalTier: RewardTier?
        let roll = randomRoller.roll(in: Constants.percentRange)
        if roll <= pity.naturalDropChanceSPlus {
            naturalTier = .sPlus
        } else if roll <= pity.naturalDropChanceSPlus + pity.naturalDropChanceS {
            naturalTier = .s
        }

        return ChestPityDropDecision(guaranteedTier: guaranteedTier, naturalTier: naturalTier)
    }

    func poolRewardId(for tier: RewardTier, pity: LocalChestPityModel) -> String? {
        let pool = tier == .sPlus ? pity.sPlusTier.pool : pity.sTier.pool
        guard !pool.isEmpty else { return nil }
        return pool[randomRoller.roll(in: 0...(pool.count - 1))]
    }
}
