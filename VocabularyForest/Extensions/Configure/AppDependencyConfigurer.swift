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
        let networkManager = APIService()
        let coreData = CoreDataManager()
        let forestData = ForestDataManager()
        let audioManager = ForestAudioService()
        let notificationManager = NotificationManager()
        let authManager = AuthManager()
        let cloudSyncManager = ForestSyncManager()
        let playerDataManager = PlayerDataManager()
        let forestAdventure = ForestAdventureService(forestManager: forestData, playerManager: playerDataManager, coreData: coreData)
        coreData.notificationManager = notificationManager
        cloudSyncManager.dataManager = forestData
        forestData.notificationManager = notificationManager
        DC.shared.register(type: .singleInstance(coreData), for: CoreDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(networkManager), for: APIServiceProtocol.self)
        DC.shared.register(type: .singleInstance(audioManager), for: AudioServiceProtocol.self)
        DC.shared.register(type: .singleInstance(notificationManager), for: (any NotificationManagerProtocol).self)
        DC.shared.register(type: .singleInstance(forestData), for: ForestDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(authManager), for: (any AuthManagerProtocol).self)
        DC.shared.register(type: .singleInstance(cloudSyncManager), for: ForestSyncManager.self)
        DC.shared.register(type: .singleInstance(playerDataManager), for: PlayerDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(forestAdventure), for: ForestAdventureServiceProtocol.self)
        forestData.checkGame(contextType: .background)
        cloudSyncManager.backgroundSyncIfNeeded()
    }
}
