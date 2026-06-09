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
struct QuestServiceTests {
    
    var sut: QuestServiceProtocol
    var mockForestData: MockForestDataManager
    var mockRewardRepository: MockRewardRepository
    
    init( ) {
        mockForestData = ForestDataManager()
        mockRewardRepository = MockRewardRepository()
        sut = QuestService(forestManager: mockForestData, rewardRepository: mockRewardRepository)
    }
    
    @Test("Quest tamamlandığında doğru reward claim ediliyor mu?")
    func testClaimQuestReward() async throws {
        
        let dummyModel = LocalQuestRewardModel.mock()
        
        mockRewardRepository.processReturnValue = LocalRewardModel(rewardCount: 10, reward: .standart(model: dummyModel))
     
        let result = await sut.claimQuestReward(quest: QuestModel.mock())
        
        #expect(mockRewardRepository.claimCallCount == 1, "Ödül veritabanına eklenmedi!")
    }
}
