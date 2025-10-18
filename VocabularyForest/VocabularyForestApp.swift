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
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SplashUI().background(.backgroundSystem)
        }
    }
}
