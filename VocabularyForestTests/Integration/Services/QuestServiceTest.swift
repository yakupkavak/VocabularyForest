//
//  MockQuestService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.06.2026.
//

@testable import VocabularyForest
import Foundation
import Testing
import Combine

@Suite("Quest Service Tests", .tags(.system))
@MainActor
struct QuestServiceTests {
    
    var sut: QuestServiceProtocol
    var forestDataManager: ForestDataManagerProtocol
    var mockRewardRepository: MockRewardRepository
    
    init( ) {
        let coreData = CoreDataManager(inMemory: true)
        let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
        forestDataManager = forestData
        mockRewardRepository = MockRewardRepository()
        mockRewardRepository.processReturnValue = LocalRewardModel(rewardCount: 2, reward: LocalRewardType.mock())
        sut = QuestService(forestManager: forestDataManager, rewardRepository: mockRewardRepository)
    }
    
    @Test("Can service convert remote config file")
    func convertRemoteData() async throws {
        forestDataManager.createForest(contextType: .main)
        let questData = try await TestBundleHelper.loadMockJSON(filename: "mock_quests_config", model: RemoteQuestListModel.self)
        await sut.convertRemoteToCacheQuest(list: questData)
        #expect(sut.questList.contains { $0.id == "daily_nature_elemental_competitive_gold_target4_reward4" }, "Quest List added")
    }
    
    @Test
    func testUserClaimRewards() async throws {
        let mockQuest = QuestTrackModel(id: "1", lastUpdatedDate: Date(), status: .completed, currentProgressCount: 10)
        forestDataManager.createForest(contextType: .main)
        try forestDataManager.importQuest(track: mockQuest, contextType: .main)
        
    }
    
    @Test("Could convert remote rewards")
    @MainActor
    func testAllRewardsConvertedSuccessfully() async throws {
        
        forestDataManager.createForest(contextType: .main)
        let questData = try await TestBundleHelper.loadMockJSON(filename: "mock_quests_config", model: RemoteQuestListModel.self)
        
        await sut.convertRemoteToCacheQuest(list: questData)
        let expectedCount = questData.items.count
        let actualCount = sut.questList.count
        #expect(
            actualCount == expectedCount,
            " expected \(expectedCount) and actual \(actualCount) are not equal!"
        )
       
        for quest in sut.questList {
            #expect(quest.reward.rewardCount > 0, "\(quest.id) in this quest id reward nil!")
            switch quest.reward.reward {
            case .standart(let model):
                #expect(!model.assetName.isEmpty, "\(quest.id) in this quest asset name empty")
            case .chest(let model):
                #expect(!model.id.isEmpty, "\(quest.id) in this quest chesd id nil!")
            }
        }
    }
}
