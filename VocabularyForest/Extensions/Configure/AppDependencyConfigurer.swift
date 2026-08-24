//
//  AppDependencyConfigurer.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.03.2026.
//

import DependencyContainer
import FirebaseFirestore
import Foundation

enum AppDependencyConfigurer {
    static func configure() {
        // UI tests must not pollute production analytics data.
        let analyticsService: AnalyticsServiceProtocol = UITestConstants.isUITestRun
            ? NoopAnalyticsService()
            : FirebaseAnalyticsService(logger: AppLogger.shared)
        // The stored opt-out has to be replayed before anything is logged; Firebase keeps
        // collection enabled across launches otherwise and the first events would leak.
        let analyticsConsentStore = AnalyticsConsentStore()
        analyticsService.setCollectionEnabled(analyticsConsentStore.isAnalyticsEnabled)
        let vocabularyBaseURLProvider = VocabularyBaseURLProvider()
        let networkManager = APIService(vocabularyBaseURLProvider: vocabularyBaseURLProvider)
        let coreData = CoreDataManager()
        let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
        let forestEntityService = ForestEntityServiceAdapter(coreDataManager: coreData)
        let audioManager = ForestAudioService()
        let notificationManager = NotificationManager()
        let authManager = AuthManager(analyticsService: analyticsService)
        let syncCursorStore = ForestSyncCursorStore()
        let cloudSyncManager = ForestSyncManager(
            db: Firestore.firestore(),
            conflictResolver: LastWriteWinsConflictResolver(),
            cursorStore: syncCursorStore,
            analyticsService: analyticsService
        )
        let accountCloudDeletionService = AccountCloudDeletionService(
            db: Firestore.firestore(),
            cursorStore: syncCursorStore,
            dataManager: forestData
        )
        let playerDataManager = PlayerDataManager(backgroundContext: coreData.backgroundContext, viewContext: coreData.viewContext)
        let remoteConfigRepository = RemoteConfigRepository()
        let documentRepository = DocumentaryRepository()
        let offlineAssetManager = OfflineAssetManager()
        let chestPityService = ChestPityService(
            counterStore: ForestChestPityCounterStore(forestManager: forestData, fallbackStore: ChestPityCounterStore()),
            randomRoller: SystemRandomRoller()
        )
        let chestRepository = ChestRepository(assetManager: offlineAssetManager, apiService: networkManager, pityService: chestPityService)
        let rewardRepository = RewardRepository(assetManager: offlineAssetManager, apiService: networkManager, chestRepository: chestRepository, forestManager: forestData)
        let rewardAssetHydrationService = RewardAssetHydrationService(assetDownloader: rewardRepository, remoteConfigRepository: remoteConfigRepository, offlineAssetManager: offlineAssetManager, forestManager: forestData)
        let dailySpinService = DailySpinService(forestManager: forestData, rewardRepository: rewardRepository)
        let weeklyRewardService = WeeklyRewardService(forestManager: forestData, rewardRepository: rewardRepository)
        let adventureSeasonProgressStore = AdventureRoadSeasonProgressStore(coreDataManager: coreData, forestDataManager: forestData)
        let adventureRoadService = AdventureRoadService(forestManager: forestData, rewardRepository: rewardRepository, seasonProgressStore: adventureSeasonProgressStore)
        let questService = QuestService(forestManager: forestData, rewardRepository: rewardRepository)
        let marketService = MarketService(forestManager: forestData, rewardRepository: rewardRepository, purchaseLimitStore: MarketPurchaseLimitStore())
        let storePurchaseService = StoreKitPurchaseService()
        let packageService = PackageService(storeService: storePurchaseService, rewardRepository: rewardRepository, chestRepository: chestRepository)
        let rewardNotificationService = RewardNotificationService(forestManager: forestData, adventureRoadService: adventureRoadService)
        let cloudRestorePromptService = CloudRestorePromptService(authManager: authManager, syncManager: cloudSyncManager, forestManager: forestData, assetHydrationService: rewardAssetHydrationService, analyticsService: analyticsService)
        let gameManager = GameManager()
        let rewardedAdService = InstantGrantRewardedAdService()
        let forestAdventure = ForestAdventureService(forestManager: forestData, playerManager: playerDataManager, coreData: coreData, remoteConfig: remoteConfigRepository, documentRepository: documentRepository, rewardRepository: rewardRepository, questService: questService, dailySpinService: dailySpinService, weeklyRewardService: weeklyRewardService, adventureRoadService: adventureRoadService, marketService: marketService, packageService: packageService, chestService: chestRepository, gameManager: gameManager, analyticsService: analyticsService)
        coreData.notificationManager = notificationManager
        cloudSyncManager.dataManager = forestData
        cloudSyncManager.remoteConfigRepository = remoteConfigRepository
        cloudSyncManager.assetHydrationService = rewardAssetHydrationService
        forestData.notificationManager = notificationManager
        DC.shared.register(type: .singleInstance(analyticsService), for: AnalyticsServiceProtocol.self)
        DC.shared.register(type: .singleInstance(analyticsConsentStore), for: AnalyticsConsentStoreProtocol.self)
        DC.shared.register(type: .singleInstance(coreData), for: CoreDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(networkManager), for: APIServiceProtocol.self)
        DC.shared.register(type: .singleInstance(audioManager), for: AudioServiceProtocol.self)
        DC.shared.register(type: .singleInstance(notificationManager), for: (any NotificationManagerProtocol).self)
        DC.shared.register(type: .singleInstance(forestData), for: ForestDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(forestEntityService), for: ForestEntityServiceProtocol.self)
        DC.shared.register(type: .singleInstance(authManager), for: (any AuthManagerProtocol).self)
        DC.shared.register(type: .singleInstance(cloudSyncManager), for: ForestSyncManagerProtocol.self)
        DC.shared.register(type: .singleInstance(accountCloudDeletionService), for: AccountCloudDeletionServiceProtocol.self)
        DC.shared.register(type: .singleInstance(playerDataManager), for: PlayerDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(forestAdventure), for: ForestAdventureServiceProtocol.self)
        DC.shared.register(type: .singleInstance(remoteConfigRepository), for: RemoteConfigRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(gameManager), for: GameManagerProtocol.self)
        DC.shared.register(type: .singleInstance(rewardedAdService), for: RewardedAdServiceProtocol.self)
        DC.shared.register(type: .singleInstance(documentRepository), for: DocumentaryRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(offlineAssetManager), for: OfflineAssetManagerProtocol.self)
        DC.shared.register(type: .singleInstance(chestRepository), for: ChestRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(rewardRepository), for: RewardRepositoryProtocol.self)
        DC.shared.register(type: .singleInstance(questService), for: QuestServiceProtocol.self)
        DC.shared.register(type: .singleInstance(dailySpinService), for: DailySpinServiceProtocol.self)
        DC.shared.register(type: .singleInstance(weeklyRewardService), for: WeeklyRewardServiceProtocol.self)
        DC.shared.register(type: .singleInstance(adventureRoadService), for: AdventureRoadServiceProtocol.self)
        DC.shared.register(type: .singleInstance(adventureSeasonProgressStore), for: AdventureRoadSeasonProgressStoreProtocol.self)
        DC.shared.register(type: .singleInstance(marketService), for: MarketServiceProtocol.self)
        DC.shared.register(type: .singleInstance(storePurchaseService), for: StorePurchaseServiceProtocol.self)
        DC.shared.register(type: .singleInstance(packageService), for: PackageServiceProtocol.self)
        DC.shared.register(type: .singleInstance(rewardNotificationService), for: RewardNotificationServiceProtocol.self)
        DC.shared.register(type: .singleInstance(cloudRestorePromptService), for: CloudRestorePromptServiceProtocol.self)
        DC.shared.register(type: .singleInstance(rewardAssetHydrationService), for: RewardAssetHydrationServiceProtocol.self)
        forestData.checkGame(contextType: .background)
        // Sync is triggered from the scenePhase == .active handler, which also fires
        // on cold start; a second trigger here would race the same delta batch.
    }
}
