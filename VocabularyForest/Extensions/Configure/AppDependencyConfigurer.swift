//
//  AppDependencyConfigurer.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.03.2026.
//

import DependencyContainer
import Foundation

enum AppDependencyConfigurer {
    static func configure() {
        let vocabularyBaseURLProvider = VocabularyBaseURLProvider()
        let networkManager = APIService(vocabularyBaseURLProvider: vocabularyBaseURLProvider)
        let coreData = CoreDataManager()
        let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
        let forestEntityService = ForestEntityServiceAdapter(coreDataManager: coreData)
        let audioManager = ForestAudioService()
        let notificationManager = NotificationManager()
        let authManager = AuthManager()
        let cloudSyncManager = ForestSyncManager()
        let playerDataManager = PlayerDataManager(backgroundContext: coreData.backgroundContext, viewContext: coreData.viewContext)
        let remoteConfigRepository = RemoteConfigRepository()
        let documentRepository = DocumentaryRepository()
        let offlineAssetManager = OfflineAssetManager()
        let chestRepository = ChestRepository(assetManager: offlineAssetManager, apiService: networkManager)
        let rewardRepository = RewardRepository(assetManager: offlineAssetManager, apiService: networkManager, chestRepository: chestRepository, forestManager: forestData)
        let dailySpinService = DailySpinService(forestManager: forestData, rewardRepository: rewardRepository)
        let questService = QuestService(forestManager: forestData, rewardRepository: rewardRepository)
        let forestAdventure = ForestAdventureService(forestManager: forestData, playerManager: playerDataManager, coreData: coreData, remoteConfig: remoteConfigRepository, documentRepository: documentRepository, rewardRepository: rewardRepository, questService: questService, dailySpinService: dailySpinService, chestService: chestRepository)
        let gameManager = GameManager(remoteConfigRepository: remoteConfigRepository)
        coreData.notificationManager = notificationManager
        cloudSyncManager.dataManager = forestData
        forestData.notificationManager = notificationManager
        DC.shared.register(type: .singleInstance(coreData), for: CoreDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(networkManager), for: APIServiceProtocol.self)
        DC.shared.register(type: .singleInstance(audioManager), for: AudioServiceProtocol.self)
        DC.shared.register(type: .singleInstance(notificationManager), for: (any NotificationManagerProtocol).self)
        DC.shared.register(type: .singleInstance(forestData), for: ForestDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(forestEntityService), for: ForestEntityServiceProtocol.self)
        DC.shared.register(type: .singleInstance(authManager), for: (any AuthManagerProtocol).self)
        DC.shared.register(type: .singleInstance(cloudSyncManager), for: ForestSyncManager.self)
        DC.shared.register(type: .singleInstance(playerDataManager), for: PlayerDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(forestAdventure), for: ForestAdventureServiceProtocol.self)
        DC.shared.register(type: .singleInstance(remoteConfigRepository), for: RemoteConfigRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(gameManager), for: GameManagerProtocol.self)
        DC.shared.register(type: .singleInstance(documentRepository), for: DocumentaryRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(offlineAssetManager), for: OfflineAssetManagerProtocol.self)
        DC.shared.register(type: .singleInstance(chestRepository), for: ChestRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(rewardRepository), for: RewardRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(questService), for: QuestServiceProtocol.self)
        DC.shared.register(type: .singleInstance(dailySpinService), for: DailySpinServiceProtocol.self)
        forestData.checkGame(contextType: .background)
        cloudSyncManager.backgroundSyncIfNeeded()
    }
}
