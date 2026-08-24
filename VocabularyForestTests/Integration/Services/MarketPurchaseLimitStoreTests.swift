//
//  MarketPurchaseLimitStoreTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

@testable import VocabularyForest
import Foundation
import Testing

@Suite("Market Purchase Limit Store Tests", .tags(.gameLogic))
struct MarketPurchaseLimitStoreTests {

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "MarketPurchaseLimitStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("Purchases accumulate within the same week")
    func purchasesAccumulate() {
        let sut: MarketPurchaseLimitStoreProtocol = MarketPurchaseLimitStore(defaults: Self.makeDefaults())
        #expect(sut.purchaseCountThisWeek(itemId: "item") == 0)
        sut.registerPurchase(itemId: "item")
        sut.registerPurchase(itemId: "item")
        #expect(sut.purchaseCountThisWeek(itemId: "item") == 2)
    }

    @Test("Counter resets when the ISO week changes")
    func counterResetsNextWeek() {
        let defaults = Self.makeDefaults()
        var now = Date(timeIntervalSince1970: 1_756_000_000)
        let sut: MarketPurchaseLimitStoreProtocol = MarketPurchaseLimitStore(
            defaults: defaults,
            dateProvider: { now }
        )
        sut.registerPurchase(itemId: "item")
        #expect(sut.purchaseCountThisWeek(itemId: "item") == 1)

        now = now.addingTimeInterval(7 * 24 * 60 * 60)
        #expect(sut.purchaseCountThisWeek(itemId: "item") == 0)
    }

    @Test("Items are counted independently")
    func itemsCountedIndependently() {
        let sut: MarketPurchaseLimitStoreProtocol = MarketPurchaseLimitStore(defaults: Self.makeDefaults())
        sut.registerPurchase(itemId: "first")
        #expect(sut.purchaseCountThisWeek(itemId: "second") == 0)
    }
}
