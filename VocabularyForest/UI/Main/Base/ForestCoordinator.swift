//
//  ForestCoordinator.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.03.2026.
//

import DependencyContainer
import SwiftUI
import Combine

protocol VocabularyForestCoordinatorProtocol {
    func startForestUI() -> AnyView
    func startBattleUI(gameType: BattleQuestionType, battleMode: BattleEnemyModel, gameLevel: GameLevel, selectedBookcase: BookcaseModel?) -> AnyView
    func startLearningFeedUI() -> AnyView
    func startSettingsUI() -> AnyView
    func startBookcaseDetailUI(bookcaseName: String, learningLanguage: String, meaningLanguage: String) -> AnyView
    func startBookcaseFeedUI() -> AnyView
    func startBookcasePacketsUI() -> AnyView
    func startCreateBookUI() -> AnyView
    func startCreateBookcaseUI() -> AnyView
    func startClaimRewardUI(claimReward: LocalRewardModel, onClaim: @escaping ([LocalRewardModel]) -> Void) -> AnyView
}

final class VocabularyForestCoordinator: VocabularyForestCoordinatorProtocol, ObservableObject{
    
    @EnvironmentObject var tabbarController: TabBarController
    private let resolver: DCResolve
    
    private var cachedSplashViewModel: SplashViewModel?
    private var cachedForestViewModel: ForestViewModel?
    private var cachedBattleViewModel: BattleViewModel?
    private var cachedLearningFeedViewModel: LearningFeedViewModel?
    private var cachedSettingsViewModel: SettingsViewModel?
    private var cachedBookcaseDetailViewModel: BookcaseDetailViewModel?
    private var cachedBookcaseFeedViewModel: BookcaseFeedViewModel?
    private var cachedBookcasePacketsViewModel: BookcasePacketsViewModel?
    private var cachedCreateBookViewModel: CreateBookViewModel?
    private var cachedCreateBookcaseViewModel: CreateBookcaseViewModel?

    init(resolver: DCResolve) {
        self.resolver = resolver
    }
    
    func startSplashUI() -> AnyView {
        if let cachedVM = cachedSplashViewModel {
            return AnyView(SplashUI(viewModel: cachedVM))
        }
        let playerManager = resolver.resolve(type: .singleInstance, for: PlayerDataManagerProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let forestData = resolver.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self)
        let remoteConfigRepository = resolver.resolve(type: .singleInstance, for: RemoteConfigRepositoryProtocol.self)
        let forestControllerService = ForestInitializerService(
            forestManager: forestData,
            playerManager: playerManager,
            coreData: coreData
        )
        let restorePromptService = resolver.resolve(type: .singleInstance, for: CloudRestorePromptServiceProtocol.self)
        let assetHydrationService = resolver.resolve(type: .singleInstance, for: RewardAssetHydrationServiceProtocol.self)
        let viewModel = SplashViewModel(forestController: forestControllerService, restorePromptService: restorePromptService, assetHydrationService: assetHydrationService)
        self.cachedSplashViewModel = viewModel
        return AnyView(
            SplashUI(viewModel: viewModel)
        )
    }

    func startForestUI() -> AnyView {
        if let cachedVM = cachedForestViewModel {
            return AnyView(ForestUI(viewModel: cachedVM))
        }
        
        let audioService = resolver.resolve(type: .singleInstance, for: AudioServiceProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let forestData = resolver.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self)
        let forestEntityService = resolver.resolve(type: .singleInstance, for: ForestEntityServiceProtocol.self)
        let adventureService = resolver.resolve(type: .singleInstance, for: ForestAdventureServiceProtocol.self)
        let remoteConfigRepository = resolver.resolve(type: .singleInstance, for: RemoteConfigRepositoryProtocol.self)
        let playerManager = resolver.resolve(type: .singleInstance, for: PlayerDataManagerProtocol.self)
        let questService = resolver.resolve(type: .singleInstance, for: QuestServiceProtocol.self)
        let dailySpinService = resolver.resolve(type: .singleInstance, for: DailySpinServiceProtocol.self)
        let weeklyRewardService = resolver.resolve(type: .singleInstance, for: WeeklyRewardServiceProtocol.self)
        let adventureRoadService = resolver.resolve(type: .singleInstance, for: AdventureRoadServiceProtocol.self)
        let marketService = resolver.resolve(type: .singleInstance, for: MarketServiceProtocol.self)
        let assetHydrationService = resolver.resolve(type: .singleInstance, for: RewardAssetHydrationServiceProtocol.self)
        let viewModel = ForestViewModel(
            audioService: audioService,
            coreDataManager: coreData,
            forestDataManager: forestData,
            forestEntityService: forestEntityService,
            forestAdventureService: adventureService,
            remoteConfigRepository: remoteConfigRepository,
            playerDataManager: playerManager,
            questService: questService,
            dailySpinService: dailySpinService,
            weeklyRewardService: weeklyRewardService,
            adventureRoadService: adventureRoadService,
            marketService: marketService,
            assetHydrationService: assetHydrationService
        )

        self.cachedForestViewModel = viewModel
        return AnyView(
            ForestUI(viewModel: viewModel)
        )
    }
    
    func startBattleUI(gameType: BattleQuestionType, battleMode: BattleEnemyModel, gameLevel: GameLevel, selectedBookcase: BookcaseModel?) -> AnyView {
        if let cachedVM = cachedBattleViewModel {
            return AnyView(BattleUI(viewModel: cachedVM, gameType: gameType, battleMode: battleMode, gameLevel: gameLevel, selectedBookcase: selectedBookcase))
        }
        
        let audioService = resolver.resolve(type: .singleInstance, for: AudioServiceProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let forestData = resolver.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self)
        let playerManager = resolver.resolve(type: .singleInstance, for: PlayerDataManagerProtocol.self)
        let questService = resolver.resolve(type: .singleInstance, for: QuestServiceProtocol.self)
        let gameManager = resolver.resolve(type: .singleInstance, for: GameManagerProtocol.self)
        let viewModel = BattleViewModel(
            coreDataManager: coreData,
            audioService: audioService,
            forestDataManager: forestData,
            playerDataManager: playerManager,
            questService: questService,
            gameManager: gameManager,
        )
        
        self.cachedBattleViewModel = viewModel
        return AnyView(
            BattleUI(viewModel: viewModel, gameType: gameType, battleMode: battleMode, gameLevel: gameLevel, selectedBookcase: selectedBookcase)
        )
    }
    
    func startLearningFeedUI() -> AnyView {
        if let cachedVM = cachedLearningFeedViewModel {
            return AnyView(LearningFeedUI(viewModel: cachedVM))
        }
        
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = LearningFeedViewModel(coreDataManager: coreData)
        
        self.cachedLearningFeedViewModel = viewModel
        return AnyView(
            LearningFeedUI(viewModel: viewModel)
        )
    }
    
    func startSettingsUI() -> AnyView {
        if let cachedVM = cachedSettingsViewModel {
            return AnyView(SettingsUI(viewModel: cachedVM))
        }
        
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let notification = resolver.resolve(type: .singleInstance, for: (any NotificationManagerProtocol).self)
        let auth = resolver.resolve(type: .singleInstance, for: (any AuthManagerProtocol).self)
        let sync = resolver.resolve(type: .singleInstance, for: ForestSyncManager.self)
        let forestData = resolver.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self)
        let playerManager = resolver.resolve(type: .singleInstance, for: PlayerDataManagerProtocol.self)
        let restorePromptService = resolver.resolve(type: .singleInstance, for: CloudRestorePromptServiceProtocol.self)
        let viewModel = SettingsViewModel(
            notificationManager: notification,
            coreDataManager: coreData,
            authManager: auth,
            syncManager: sync,
            forestManager: forestData,
            playerManager: playerManager,
            restorePromptService: restorePromptService
        )
        
        self.cachedSettingsViewModel = viewModel
        return AnyView(
            SettingsUI(viewModel: viewModel)
        )
    }
    
    func startBookcaseDetailUI(bookcaseName: String, learningLanguage: String, meaningLanguage: String) -> AnyView {
        if let cachedVM = cachedBookcaseDetailViewModel {
            return AnyView(BookcaseDetailUI(viewModel: cachedVM))
        }
        
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = BookcaseDetailViewModel(
            bookcaseName: bookcaseName,
            learningLanguage: learningLanguage,
            meaningLanguage: meaningLanguage,
            dataManager: coreData
        )
        
        self.cachedBookcaseDetailViewModel = viewModel
        return AnyView(
            BookcaseDetailUI(viewModel: viewModel)
        )
    }
    
    func startBookcaseFeedUI() -> AnyView {
        if let cachedVM = cachedBookcaseFeedViewModel {
            return AnyView(BookcaseFeedUI(viewModel: cachedVM))
        }
        
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = BookcaseFeedViewModel(coreDataManager: coreData)
        
        self.cachedBookcaseFeedViewModel = viewModel
        return AnyView(
            BookcaseFeedUI(viewModel: viewModel)
        )
    }
    
    func startBookcasePacketsUI() -> AnyView {
        if let cachedVM = cachedBookcasePacketsViewModel {
            return AnyView(BookcasePacketsUI(viewModel: cachedVM))
        }
        
        let networkService = resolver.resolve(type: .singleInstance, for: APIServiceProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = BookcasePacketsViewModel(networkService: networkService, dataManager: coreData)
        
        self.cachedBookcasePacketsViewModel = viewModel
        return AnyView(
            BookcasePacketsUI(viewModel: viewModel)
        )
    }
    
    func startCreateBookUI() -> AnyView {
        if let cachedVM = cachedCreateBookViewModel {
            return AnyView(CreateBookUI(viewModel: cachedVM))
        }
        
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = CreateBookViewModel(coreDataManager: coreData)
        
        self.cachedCreateBookViewModel = viewModel
        return AnyView(
            CreateBookUI(viewModel: viewModel)
        )
    }
    
    func startCreateBookcaseUI() -> AnyView {
        if let cachedVM = cachedCreateBookcaseViewModel {
            return AnyView(CreateBookcaseUI(viewModel: cachedVM))
        }
        
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = CreateBookcaseViewModel(coreDataManager: coreData)
        
        self.cachedCreateBookcaseViewModel = viewModel
        return AnyView(
            CreateBookcaseUI(viewModel: viewModel)
        )
    }
    
    func startClaimRewardUI(claimReward: LocalRewardModel, onClaim: @escaping ([LocalRewardModel]) -> Void) -> AnyView {
        let chestRepository = resolver.resolve(type: .singleInstance, for: ChestRepositoryProtocol.self)
        let viewModel = ClaimRewardViewModel(chestManager: chestRepository)
        return AnyView(ClaimRewardUI(viewModel: viewModel, claimReward: claimReward, onClaim: onClaim))
    }
}
