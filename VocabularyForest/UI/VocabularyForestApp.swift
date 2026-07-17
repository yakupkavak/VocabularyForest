//
//  VocabularyForestApp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import CoreData
import DependencyContainer
import GoogleMobileAds
import AppTrackingTransparency

@main
struct VocabularyForestApp: App {
    
    // MARK: - PROPERTIES
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var routerLearning = LearningRouter()
    @StateObject private var routerBookcase = BookcaseRouter()
    @StateObject private var routerCreateBookcase = CreateBookRouter()
    @StateObject private var tabbarController = TabBarController()
    @StateObject private var coordinator: VocabularyForestCoordinator
    
    // MARK: - INIT
    
    init() {
        FirebaseBootstrap.configureIfNeeded()
        AppDependencyConfigurer.configure()
        MobileAds.shared.start(completionHandler: nil)
        let resolver = DC.shared
        _coordinator = StateObject(wrappedValue: VocabularyForestCoordinator(resolver: resolver))
    }
    
    // MARK: - VIEWS
    
    var body: some Scene {
        WindowGroup {
            coordinator.startSplashUI().background(.backgroundSystem).onChange(of: scenePhase) { phase in
                let rewardNotificationService = DC.shared.resolve(type: .singleInstance, for: RewardNotificationServiceProtocol.self)
                if phase == .background {
                    let coreDataManager = DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
                    coreDataManager.save(type: .main)
                    Task {
                        await rewardNotificationService.scheduleRewardNotifications()
                    }
                } else if phase == .active {
                    rewardNotificationService.cancelRewardNotifications()
                    // Reklamlar yüklenmeden önce ATT izni. Sistem yalnızca ilk seferde sorar.
                    ATTrackingManager.requestTrackingAuthorization { _ in }
                }
            }.environmentObject(routerBookcase).environmentObject(routerCreateBookcase).environmentObject(routerLearning)
                .environmentObject(tabbarController).environmentObject(coordinator)
                .installToast(position: .bottom)
                .withGlobalPopup()
        }
    }
}
