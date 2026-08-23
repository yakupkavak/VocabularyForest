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
    private let assetHydrationService: RewardAssetHydrationServiceProtocol

    init(
        forestController: ForestInitializerServiceProtocol,
        restorePromptService: CloudRestorePromptServiceProtocol,
        assetHydrationService: RewardAssetHydrationServiceProtocol
    ) {
        self.forestController = forestController
        self.restorePromptService = restorePromptService
        self.assetHydrationService = assetHydrationService
        super.init()
        setupApplication()
    }

    private func setupApplication() {
        Task(priority: .background) {
            await forestController.initializeNewGame()
            // Try to download the entities still queued (assetReady == false) in the background.
            // Idempotent: it makes no network call for assets that are already ready.
            Task(priority: .background) { [assetHydrationService] in
                await assetHydrationService.hydratePendingAssets()
            }
            // After local setup: if the signed-in account has a different forest in the
            // cloud (e.g. reinstall with persisted auth), ask the user which one to keep.
            await restorePromptService.checkAndPromptIfNeeded()
        }
    }
    
}
