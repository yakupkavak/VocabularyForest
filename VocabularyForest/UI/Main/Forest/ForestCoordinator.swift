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
}

final class VocabularyForestCoordinator: VocabularyForestCoordinatorProtocol, ObservableObject{    
    @EnvironmentObject var tabbarController: TabBarController
    private let resolver: DCResolve
    
    init(resolver: DCResolve) {
        self.resolver = resolver
    }

    func startForestUI() -> AnyView {
        let audioService = resolver.resolve(type: .singleInstance, for: AudioServiceProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let forestData = resolver.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self)
        let viewModel = ForestViewModel(
            audioService: audioService,
            coreDataManager: coreData,
            forestDataManager: forestData
        )
        
        return AnyView(
            ForestUI(viewModel: viewModel)
        )
    }
    
    func startBattleUI(gameType: BattleQuestionType, battleMode: BattleEnemyModel, gameLevel: GameLevel, selectedBookcase: BookcaseModel?) -> AnyView {
        let audioService = resolver.resolve(type: .singleInstance, for: AudioServiceProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let forestData = resolver.resolve(type: .singleInstance, for: ForestDataManagerProtocol.self)
        let viewModel = BattleViewModel(
            coreDataManager: coreData,
            audioService: audioService,
            forestDataManager: forestData
        )
        
        return AnyView(
            BattleUI(viewModel: viewModel, gameType: gameType, battleMode: battleMode, gameLevel: gameLevel, selectedBookcase: selectedBookcase)
        )
    }
    
    func startLearningFeedUI() -> AnyView {
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = LearningFeedViewModel(coreDataManager: coreData)
        return AnyView(
            LearningFeedUI(viewModel: viewModel)
        )
    }
    
    func startSettingsUI() -> AnyView {
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let notification = resolver.resolve(type: .singleInstance, for: (any NotificationManagerProtocol).self)

        let viewModel = SettingsViewModel(
            notificationManager: notification,
            coreDataManager: coreData
        )
        return AnyView(
            SettingsUI(viewModel: viewModel)
        )
    }
    
    func startBookcaseDetailUI(bookcaseName: String, learningLanguage: String, meaningLanguage: String) -> AnyView {
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = BookcaseDetailViewModel(
            bookcaseName: bookcaseName,
            learningLanguage: learningLanguage,
            meaningLanguage: meaningLanguage,
            dataManager: coreData
        )
        return AnyView(
            BookcaseDetailUI(viewModel: viewModel)
        )
    }
    func startBookcaseFeedUI() -> AnyView {
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = BookcaseFeedViewModel(coreDataManager: coreData)
        return AnyView(
            BookcaseFeedUI(viewModel: viewModel)
        )
    }
    func startBookcasePacketsUI() -> AnyView {
        let networkService = resolver.resolve(type: .singleInstance, for: APIServiceProtocol.self)
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = BookcasePacketsViewModel(networkService: networkService, dataManager: coreData)
        return AnyView(
            BookcasePacketsUI(viewModel: viewModel)
        )
    }
    func startCreateBookUI() -> AnyView {
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = CreateBookViewModel(coreDataManager: coreData)
        return AnyView(
            CreateBookUI(viewModel: viewModel)
        )
    }
    func startCreateBookcaseUI() -> AnyView {
        let coreData = resolver.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
        let viewModel = CreateBookcaseViewModel(coreDataManager: coreData)
        return AnyView(
            CreateBookcaseUI(viewModel: viewModel)
        )
    }
    
}
