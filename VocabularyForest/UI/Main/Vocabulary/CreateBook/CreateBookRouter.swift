//
//  CreateBookRouter.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.10.2025.
//

import SwiftUI
import Combine

final class CreateBookRouter: ObservableObject {
    
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
        guard !navPath.isEmpty else { return }
        navPath.removeLast()
    }
    
    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }
}

extension CreateBookRouter {
    public enum Destination: Codable, Hashable {
        case bookcaseList
    }
}
