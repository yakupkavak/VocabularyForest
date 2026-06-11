//
//  ForestDataManagerTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.06.2026.
//

@testable import VocabularyForest
import Testing
import Foundation

@Suite("Forest Data Manager Tests", .tags(.database))
@MainActor
struct ForestDataManagerTests {
    
    var sut: ForestDataManagerProtocol
    
    init() {
        let inMemoryCoreData = CoreDataManager(inMemory: true)
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
    
    // MARK: - UPDATE RAIN
    
    @Test("Can user update rain")
    func canUserUpdateRain() throws {
        createForest()
        
    }
    
    @Test("User can't update rain without create forest")
    func testCheckAndUpdateRain_ThrowsEmptyForest() throws {
        #expect(throws: ForestError.emptyForest) {
            try sut.checkAndUpdateRain(contextType: .main)
        }
    }
}

private extension ForestDataManagerTests {
    func createForest() {
        let createResult = sut.createForest(contextType: .main)
        #expect(createResult.status == .success)
    }
}
