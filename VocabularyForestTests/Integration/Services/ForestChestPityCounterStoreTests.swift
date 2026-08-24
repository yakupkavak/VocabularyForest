//
//  ForestChestPityCounterStoreTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

@testable import VocabularyForest
import Foundation
import Testing

@Suite("Forest Chest Pity Counter Store Tests", .tags(.database))
struct ForestChestPityCounterStoreTests {

    let sut: ChestPityCounterStoreProtocol
    let fallback: MockChestPityCounterStore

    init() {
        let coreData = CoreDataManager(inMemory: true)
        let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
        let createResult = forestData.createForest(contextType: .background)
        #expect(createResult.status == .success, "Forest creation failed in test setup")
        fallback = MockChestPityCounterStore()
        sut = ForestChestPityCounterStore(forestManager: forestData, fallbackStore: fallback)
    }

    @Test("Known counter groups persist on the forest entity")
    func knownGroupsPersistOnForest() {
        #expect(sut.openCount(group: "nature") == 0)
        sut.setOpenCount(12, group: "nature")
        sut.setOpenCount(3, group: "antique")
        sut.setOpenCount(47, group: "general")
        #expect(sut.openCount(group: "nature") == 12)
        #expect(sut.openCount(group: "antique") == 3)
        #expect(sut.openCount(group: "general") == 47)
    }

    @Test("Unknown counter groups fall back to the local store")
    func unknownGroupUsesFallback(){
        sut.setOpenCount(5, group: "seasonal-2027")
        #expect(fallback.openCount(group: "seasonal-2027") == 5)
        #expect(sut.openCount(group: "seasonal-2027") == 5)
    }
}
