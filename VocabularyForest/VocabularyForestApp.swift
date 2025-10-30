//
//  VocabularyForestApp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import CoreData

@main
struct VocabularyForestApp: App {
    
    // MARK: - PROPERTIES
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var routerBookcase = BookcaseRouter()
    @StateObject private var routerCreateBookcase = CreateBookRouter()

    // MARK: - VIEWS
    
    var body: some Scene {
        WindowGroup {
            SplashUI().background(.backgroundSystem).onChange(of: scenePhase) { _ in
                CoreDataManager.shared.save()
            }.environmentObject(routerBookcase).environmentObject(routerCreateBookcase)
        }
    }
}
