//
//  CreateBookRouter.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.10.2025.
//

import SwiftUI
import Combine

final class LearningRouter: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var navPath = NavigationPath()
    
    // MARK: - HELPERS

    func navigate(to destination: Destination) {
        navPath.append(destination)
    }
    
    func navigateWithClear(to destination: Destination) {
        navPath = NavigationPath()
        navPath.append(destination)
    }
    
    func navigateBack() {
        navPath.removeLast()
    }
    
    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }
}

extension LearningRouter {
    public enum Destination: Codable, Hashable {
        case forest
        case flashCard
        case game(BattleQuestionType, BattleEnemyModel, GameLevel)
    }
}
