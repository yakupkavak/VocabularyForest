//
//  SplashViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation

class SplashViewModel: BaseViewModel {
    
    private let forestController: ForestInitializerServiceProtocol
    private let restorePromptService: CloudRestorePromptServiceProtocol
    
    init(
        forestController: ForestInitializerServiceProtocol,
        restorePromptService: CloudRestorePromptServiceProtocol
    ) {
        self.forestController = forestController
        self.restorePromptService = restorePromptService
        super.init()
        setupApplication()
    }
    
    private func setupApplication() {
        Task(priority: .background) {
            await forestController.initializeNewGame()
            // After local setup: if the signed-in account has a different forest in the
            // cloud (e.g. reinstall with persisted auth), ask the user which one to keep.
            await restorePromptService.checkAndPromptIfNeeded()
        }
    }
    
}
