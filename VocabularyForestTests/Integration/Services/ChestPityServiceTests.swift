//
//  ChestPityServiceTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

@testable import VocabularyForest
import Foundation
import Testing

// MARK: - MOCKS

final class MockChestPityCounterStore: ChestPityCounterStoreProtocol {
    private var counts: [String: Int] = [:]

    func openCount(group: String) -> Int {
        counts[group] ?? 0
    }

    func setOpenCount(_ count: Int, group: String) {
        counts[group] = count
    }
}

/// Returns queued values in order; falls back to the range upper bound so an
/// unqueued roll never triggers a natural drop by accident.
final class MockRandomRoller: RandomRollerProtocol {
    var queuedRolls: [Int] = []

    func roll(in range: ClosedRange<Int>) -> Int {
        queuedRolls.isEmpty ? range.upperBound : queuedRolls.removeFirst()
    }
}

// MARK: - TESTS

@Suite("Chest Pity Service Tests", .tags(.gameLogic))
struct ChestPityServiceTests {

    let sut: ChestPityServiceProtocol
    let counterStore: MockChestPityCounterStore
    let randomRoller: MockRandomRoller

    init() {
        counterStore = MockChestPityCounterStore()
        randomRoller = MockRandomRoller()
        sut = ChestPityService(counterStore: counterStore, randomRoller: randomRoller)
    }

    private var naturePity: LocalChestPityModel {
        LocalChestPityModel(
            counterGroup: "nature",
            sTier: LocalChestPityTierModel(threshold: 10, pool: ["reward-plant-goldenfern"]),
            sPlusTier: LocalChestPityTierModel(threshold: 50, pool: ["reward-plant-aurorabloom"]),
            naturalDropChanceS: 3,
            naturalDropChanceSPlus: 1
        )
    }

    @Test("Tenth open grants a guaranteed S drop")
    func tenthOpenGrantsS() {
        counterStore.setOpenCount(9, group: "nature")
        let decision = sut.registerOpen(pity: naturePity)
        #expect(decision.guaranteedTier == .s)
        #expect(counterStore.openCount(group: "nature") == 10)
    }

    @Test("Fiftieth open grants S+ instead of S")
    func fiftiethOpenGrantsSPlus() {
        counterStore.setOpenCount(49, group: "nature")
        let decision = sut.registerOpen(pity: naturePity)
        #expect(decision.guaranteedTier == .sPlus)
    }

    @Test("Counter keeps cycling after the first S+ milestone")
    func counterCyclesPastSPlus() {
        counterStore.setOpenCount(59, group: "nature")
        let decision = sut.registerOpen(pity: naturePity)
        #expect(decision.guaranteedTier == .s)
    }

    @Test("Regular open grants nothing without a lucky roll")
    func regularOpenGrantsNothing() {
        counterStore.setOpenCount(4, group: "nature")
        let decision = sut.registerOpen(pity: naturePity)
        #expect(decision.guaranteedTier == nil)
        #expect(decision.naturalTier == nil)
    }

    @Test("Natural roll of 1 percent grants S+ and does not reset the counter")
    func naturalRollGrantsSPlus() {
        counterStore.setOpenCount(4, group: "nature")
        randomRoller.queuedRolls = [1]
        let decision = sut.registerOpen(pity: naturePity)
        #expect(decision.naturalTier == .sPlus)
        #expect(counterStore.openCount(group: "nature") == 5)
    }

    @Test("Natural roll inside the S band grants S")
    func naturalRollGrantsS() {
        randomRoller.queuedRolls = [4]
        let decision = sut.registerOpen(pity: naturePity)
        #expect(decision.naturalTier == .s)
    }

    @Test("Pool reward id comes from the tier matching pool")
    func poolRewardIdMatchesTier() {
        randomRoller.queuedRolls = [0, 0]
        #expect(sut.poolRewardId(for: .s, pity: naturePity) == "reward-plant-goldenfern")
        #expect(sut.poolRewardId(for: .sPlus, pity: naturePity) == "reward-plant-aurorabloom")
    }

    @Test("Progress reports the next guarantee correctly near the S+ milestone")
    func progressNearSPlus() {
        counterStore.setOpenCount(47, group: "nature")
        let progress = sut.progress(for: naturePity)
        #expect(progress.isNextGuaranteeSPlus)
        #expect(progress.remainingOpensToNextGuarantee == 3)
    }
}
