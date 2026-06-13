//
//  ForestAdventureService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 13.06.2026.
//

@testable import VocabularyForest
import Testing

@Suite("Forest Adventure - Quest Track")
struct ForestAdventureServiceQuestTrackTests {
    
    let sut: ForestAdventureServiceProtocol
    
    init() {
        let coreData = CoreDataManager(inMemory: true)
        let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
        let playerManager = PlayerDataManager()
        self.sut = ForestAdventureService(
            forestManager: forestData,
            playerManager: <#T##any PlayerDataManagerProtocol#>,
            coreData: coreData,
            remoteConfig: <#T##any RemoteConfigRepositoryProtocol#>,
            documentRepository: <#T##any DocumentaryRepositoryProtocol#>,
            rewardRepository: <#T##any RewardRepositoryProtocol#>,
            questService: <#T##any QuestServiceProtocol#>
        )
    }
    
    @Test func correctAnswer() async throws {
        
    }
}
