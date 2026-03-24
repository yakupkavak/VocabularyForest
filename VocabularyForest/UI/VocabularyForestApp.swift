//
//  VocabularyForestApp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import CoreData
import DependencyContainer

@main
struct VocabularyForestApp: App {
    
    // MARK: - PROPERTIES
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var routerLearning = LearningRouter()
    @StateObject private var routerBookcase = BookcaseRouter()
    @StateObject private var routerCreateBookcase = CreateBookRouter()
    @StateObject private var tabbarController = TabBarController()
    private let coreDataManager = DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
    
    // MARK: - VIEWS
    
    var body: some Scene {
        WindowGroup {
            SplashUI().background(.backgroundSystem).onChange(of: scenePhase) { phase in
                if phase == .background {
                    coreDataManager.save(type: .main)
                }
            }.environmentObject(routerBookcase).environmentObject(routerCreateBookcase).environmentObject(routerLearning)
                .environmentObject(tabbarController)
                .installToast(position: .bottom)
        }
    }
}
