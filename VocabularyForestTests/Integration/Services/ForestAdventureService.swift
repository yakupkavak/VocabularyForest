//
//  ForestAdventureService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 13.06.2026.
//

@testable import VocabularyForest
import Testing
import Foundation

@Suite("Forest Adventure - Quest Track")
@MainActor
struct ForestAdventureServiceQuestTrackTests {
    
    let sut: ForestAdventureServiceProtocol
    
    init() {
        let userDefaults = UserDefaults(suiteName: "test")
        let coreData = CoreDataManager(inMemory: true)
        let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
        let playerManager = PlayerDataManager(backgroundContext: coreData.backgroundContext, viewContext: coreData.viewContext)
        let remoteConfig = RemoteConfigRepository()
        let tempTestDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempTestDirectory, withIntermediateDirectories: true)
        let documentRepository = DocumentaryRepository(directoryURL: tempTestDirectory)
        let assetManager = OfflineAssetManager(directoryURL: tempTestDirectory, userDefaults: userDefaults!)
        let networkManager = MockAPIService()
        let chestRepository = ChestRepository(assetManager: assetManager, apiService: networkManager, pityService: ChestPityService(counterStore: ChestPityCounterStore(), randomRoller: SystemRandomRoller()))
        let rewardRepository = RewardRepository(assetManager: assetManager, apiService: networkManager, chestRepository: chestRepository, forestManager: forestData)
        let questService = QuestService(forestManager: forestData, rewardRepository: rewardRepository)
        let dailySpinService = DailySpinService(forestManager: forestData, rewardRepository: rewardRepository)
        let weeklyRewardService = WeeklyRewardService(forestManager: forestData, rewardRepository: rewardRepository)
        let seasonProgressStore = AdventureRoadSeasonProgressStore(coreDataManager: coreData, forestDataManager: forestData)
        let adventureRoadService = AdventureRoadService(forestManager: forestData, rewardRepository: rewardRepository, seasonProgressStore: seasonProgressStore)
        let marketService = MarketService(forestManager: forestData, rewardRepository: rewardRepository, purchaseLimitStore: MarketPurchaseLimitStore())
        self.sut = ForestAdventureService(
            forestManager: forestData,
            playerManager: playerManager,
            coreData: coreData,
            remoteConfig: remoteConfig,
            documentRepository: documentRepository,
            rewardRepository: rewardRepository,
            questService: questService,
            dailySpinService: dailySpinService,
            weeklyRewardService: weeklyRewardService,
            adventureRoadService: adventureRoadService,
            marketService: marketService,
            chestService: chestRepository,
            gameManager: GameManager()
        )
    }
    
    @Test func correctAnswer() async throws {
        
    }
}
