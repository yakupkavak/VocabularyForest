//
//  VocabularyForestApp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import CoreData
import DependencyContainer
import FirebaseCore

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
        FirebaseApp.configure()
        AppDependencyConfigurer.configure()
        let resolver = DC.shared
        _coordinator = StateObject(wrappedValue: VocabularyForestCoordinator(resolver: resolver))
    }
    
    // MARK: - VIEWS
    
    var body: some Scene {
        WindowGroup {
            coordinator.startSplashUI().background(.backgroundSystem).onChange(of: scenePhase) { phase in
                if phase == .background {
                    let coreDataManager = DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
                    coreDataManager.save(type: .main)
                }
            }.environmentObject(routerBookcase).environmentObject(routerCreateBookcase).environmentObject(routerLearning)
                .environmentObject(tabbarController).environmentObject(coordinator)
                .installToast(position: .bottom)
                .withGlobalPopup()
        }
    }
}
