//
//  ForestDataManagerTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.06.2026.
//

@testable import VocabularyForest
import Testing
import Foundation
import CoreData

// MARK: - FOREST TEST HELPER PROTOCOL

protocol ForestTestHelperProtocol {
    var sut: ForestDataManagerProtocol { get }
    var inMemoryCoreData: CoreDataManager { get }
}

extension ForestTestHelperProtocol {
    func createForest() {
        let createResult = sut.createForest(contextType: .main)
        #expect(createResult.status == .success, "Forest creation failed in helper!")
    }
    
    func timeTravel(hours: Int) {
        inMemoryCoreData.viewContext.performAndWait {
            let request = NSFetchRequest<Forest>(entityName: "Forest")
            if let forest = try? inMemoryCoreData.viewContext.fetch(request).first {
                let timeIntervalInSeconds = Double(-hours * 3600)
                forest.lastRainUpdateDate = Date().addingTimeInterval(timeIntervalInSeconds)
                try? inMemoryCoreData.viewContext.save()
            }
        }
    }
}

// MARK: - FOREST QUEST TRACK TESTS

@Suite("Forest Data Manager - Quest Track test", .tags(.database, .questTrack))
@MainActor
struct ForestDataManagerQuestTrackTests: ForestTestHelperProtocol {
    
    var sut: ForestDataManagerProtocol
    let inMemoryCoreData = CoreDataManager(inMemory: true)

    init() {
        self.sut = ForestDataManager(mainContext: inMemoryCoreData.viewContext, backgroundContext: inMemoryCoreData.backgroundContext)
    }
    
    @Test("Can user update quest")
    func canUserUpdateQuest() throws{
        createForest()
        let initialTrack = QuestTrackModel.mock(id: "quest_1", currentProgressCount: 0)
        try sut.importQuest(track: initialTrack, contextType: .main)
        let updatedTrack = QuestTrackModel.mock(id: "quest_1", currentProgressCount: 5)
        try sut.updateQuest(questTrack: updatedTrack, contextType: .main)
        let fetchQuest = try sut.fetchQuestTrack(id: "quest_1", contextType: .main)
        
        #expect(fetchQuest.currentProgressCount == 5, "Quest can be updated!")
    }
    
    @Test("Can user add quest track")
    func canUserAddQuestTrack() throws {
        createForest()
        let trackQuest = QuestTrackModel.mock()
        try sut.importQuest(track: trackQuest, contextType: .main)
        let fetchQuest = try sut.fetchQuestTrack(id: trackQuest.id, contextType: .main)
        #expect(trackQuest == fetchQuest, "Quest track can be added")
    }
}

// MARK: - FOREST RAIN TESTS

@Suite("Forest Data Manager - Rain Test", .tags(.database, .rain))
@MainActor
struct ForestDataManagerRainTests: ForestTestHelperProtocol {
    
    var sut: ForestDataManagerProtocol
    let inMemoryCoreData = CoreDataManager(inMemory: true)

    init() {
        self.sut = ForestDataManager(mainContext: inMemoryCoreData.viewContext, backgroundContext: inMemoryCoreData.backgroundContext)
    }
    
    // MARK: - RAIN TESTS
    
    @Test("Can user update rain")
    func canUserUpdateRain() throws {
        createForest()
        let initialRain = try sut.fetchForestStatus(contextType: .main).rainValue
        try sut.addRainValue(rain: 10, contextType: .main)
        let forestRain = try sut.fetchForestStatus(contextType: .main).rainValue
        #expect(forestRain == initialRain + 10, "Quest rain can be increased")
    }
    
    @Test("Rain value saves automaticly.")
    func forestRainAutomaticSave() throws {
        createForest()
        let initialRain = try sut.fetchForestStatus(contextType: .main).rainValue
        try sut.addRainValue(rain: 10, contextType: .main)
        let forestRain = try sut.fetchForestStatus(contextType: .background).rainValue
        #expect(forestRain == initialRain + 10, "Main context updates core data successfuly")
    }
    
    @Test("User can't update rain without create forest")
    func testCheckAndUpdateRain_ThrowsEmptyForest() throws {
        #expect(throws: ForestError.emptyForest) {
            try sut.checkAndUpdateRain(contextType: .main)
        }
    }
    
    @Test("Start rain decreases rain value correctly")
    func userCanStartsRainAndRainValueUpdates() throws {
        createForest()
        try sut.addRainValue(rain: ForestConstant.rainCostValue, contextType: .main)
        try sut.startRain(contextType: .main)
        let afterRain = try sut.fetchForestStatus(contextType: .main).rainValue
        #expect(afterRain == 0, "Rain value decreases after rains")
    }
    
    @Test("After rain forest health becomes healthy")
    func userCanStartsRainAndForestStatusUpdates() throws {
        createForest()
        timeTravel(hours: 24)
        try sut.checkAndUpdateRain(contextType: .main)
        let decayedHealth = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        #expect(decayedHealth < 100, "After time forest health couldn't decreased!")
        try sut.addRainValue(rain: ForestConstant.rainCostValue, contextType: .main)
        try sut.startRain(contextType: .main)
        let afterRainForestHealth = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        #expect(afterRainForestHealth == 100, "Rain makes forest healthy")
    }
    
    @Test("Each hour forest health decreases correctly")
    func eachHourForestHealthDecreases() throws {
        createForest()
        let initialHealth = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        timeTravel(hours: 1)
        try sut.checkAndUpdateRain(contextType: .main)
        let decayedHealth = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        #expect(decayedHealth == initialHealth - 4, "Spending an hour decreases forest health 4")
    }
    
    @Test("Forest health never drops below zero even after a long time")
    func forestHealthDoesNotDropBelowZero() throws {
        createForest()
        timeTravel(hours: 100)
        try sut.checkAndUpdateRain(contextType: .main)
        let decayedHealth = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        #expect(decayedHealth == 0, "Forest health should stop at exactly 0, not negative")
    }
    
    @Test("First time check only sets the date without decreasing health")
    func firstRainCheckSetsDateWithoutDecay() throws {
        createForest()
        let initialHealth = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        try sut.checkAndUpdateRain(contextType: .main)
        let healthAfterFirstCheck = try sut.fetchForestStatus(contextType: .main).landHealthPercentage
        #expect(healthAfterFirstCheck == initialHealth, "First check shouldn't decrease health")
    }
}

// MARK: - KILL GOLD TESTS

@Suite("Forest Data Manager - Kill Gold Test", .tags(.database))
@MainActor
struct ForestDataManagerKillGoldTests: ForestTestHelperProtocol {
    
    var sut: ForestDataManagerProtocol
    let inMemoryCoreData = CoreDataManager(inMemory: true)

    init() {
        self.sut = ForestDataManager(mainContext: inMemoryCoreData.viewContext, backgroundContext: inMemoryCoreData.backgroundContext)
    }
    
    @Test("Kill gold stays within the configured range and increases balance")
    func killGoldGrantsWithinRange() throws {
        createForest()
        let initialGold = try sut.fetchForestStatus(contextType: .main).gold
        let granted = try sut.registerKillGold(minGold: 40, maxGold: 60, dailyCap: 15, contextType: .main)
        #expect(granted >= 40 && granted <= 60, "Granted gold should stay within the min...max range")
        let afterGold = try sut.fetchForestStatus(contextType: .main).gold
        #expect(afterGold == initialGold + granted, "Balance should increase by the granted amount")
    }
    
    @Test("Kill gold stops after the daily cap is reached")
    func killGoldRespectsDailyCap() throws {
        createForest()
        let dailyCap = 15
        for _ in 0..<dailyCap {
            let granted = try sut.registerKillGold(minGold: 40, maxGold: 60, dailyCap: dailyCap, contextType: .main)
            #expect(granted > 0, "Kills within the cap should always grant gold")
        }
        let goldAtCap = try sut.fetchForestStatus(contextType: .main).gold
        let overCapGrant = try sut.registerKillGold(minGold: 40, maxGold: 60, dailyCap: dailyCap, contextType: .main)
        #expect(overCapGrant == 0, "Kills over the daily cap should not grant gold")
        let goldAfterOverCap = try sut.fetchForestStatus(contextType: .main).gold
        #expect(goldAfterOverCap == goldAtCap, "Balance should not change after the cap is reached")
    }
}
