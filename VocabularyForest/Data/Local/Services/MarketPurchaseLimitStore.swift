//
//  MarketPurchaseLimitStore.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import Foundation

protocol MarketPurchaseLimitStoreProtocol: AnyObject {
    func purchaseCountThisWeek(itemId: String) -> Int
    func registerPurchase(itemId: String)
}

// MARK: - CONSTANTS

private extension MarketPurchaseLimitStore {
    enum Constants {
        static let keyPrefix = "market.weekly_purchase."
        static let lastWeekKeySuffix = ".week"
    }
}

/// Counts purchases of weekly-capped market items (e.g. the diamond→gold
/// exchange). Counters roll over automatically when the ISO week changes,
/// so stale keys never accumulate.
final class MarketPurchaseLimitStore {

    // MARK: - PROPERTIES

    private let defaults: UserDefaults
    private let dateProvider: () -> Date

    // MARK: - INIT

    init(defaults: UserDefaults = .standard, dateProvider: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.dateProvider = dateProvider
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension MarketPurchaseLimitStore: MarketPurchaseLimitStoreProtocol {
    func purchaseCountThisWeek(itemId: String) -> Int {
        guard defaults.string(forKey: weekKey(itemId: itemId)) == currentWeekIdentifier() else {
            return 0
        }
        return defaults.integer(forKey: countKey(itemId: itemId))
    }

    func registerPurchase(itemId: String) {
        let count = purchaseCountThisWeek(itemId: itemId) + 1
        defaults.set(count, forKey: countKey(itemId: itemId))
        defaults.set(currentWeekIdentifier(), forKey: weekKey(itemId: itemId))
    }
}

// MARK: - HELPERS

private extension MarketPurchaseLimitStore {
    func countKey(itemId: String) -> String {
        Constants.keyPrefix + itemId
    }

    func weekKey(itemId: String) -> String {
        Constants.keyPrefix + itemId + Constants.lastWeekKeySuffix
    }

    /// ISO-8601 year+week so the counter resets on Monday regardless of locale.
    func currentWeekIdentifier() -> String {
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dateProvider())
        return "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
    }
}
