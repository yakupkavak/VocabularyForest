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
        DC.shared.register(type: .singleInstance(coreData), for: CoreDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(networkManager), for: APIServiceProtocol.self)
        DC.shared.register(type: .singleInstance(audioManager), for: AudioServiceProtocol.self)
        DC.shared.register(type: .singleInstance(notificationManager), for: (any NotificationManagerProtocol).self)
        DC.shared.register(type: .singleInstance(forestData), for: ForestDataManagerProtocol.self)
        DC.shared.register(type: .singleInstance(authManager), for: AuthManagerProtocol.self)
        //DC.shared.register(type: .singleInstance(forestData), for: ForestDataManagerProtocol.self)
        coreData.notificationManager = notificationManager
        forestData.checkGame(contextType: .background)
        forestData.notificationManager = notificationManager
    }
}
