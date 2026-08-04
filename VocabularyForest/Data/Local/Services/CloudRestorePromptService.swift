//
//  CloudRestorePromptService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import SwiftUI

/// Outcome of a cloud forest check, so callers (splash, settings) can react with their own UI.
enum CloudRestoreCheckOutcome {
    case notSignedIn
    /// Cloud was empty; the local forest was bound to the account and uploaded.
    case cloudLinked
    /// A different forest lives in the cloud; the conflict popup was shown to the user.
    case conflictPrompted
    /// No cloud forest and no local forest to link, or cloud matches the local forest.
    case upToDate
    case failed(Error?)
}

protocol CloudRestorePromptServiceProtocol: AnyObject {
    /// Checks whether the signed-in account has a cloud forest that differs from the local
    /// one and, if so, shows the forest conflict popup so the user decides which to keep.
    @discardableResult
    func checkAndPromptIfNeeded() async -> CloudRestoreCheckOutcome
}

final class CloudRestorePromptService {
    
    private let authManager: any AuthManagerProtocol
    private let syncManager: ForestSyncManagerProtocol
    private let forestManager: ForestDataManagerProtocol
    private let assetHydrationService: RewardAssetHydrationServiceProtocol

    init(
        authManager: any AuthManagerProtocol,
        syncManager: ForestSyncManagerProtocol,
        forestManager: ForestDataManagerProtocol,
        assetHydrationService: RewardAssetHydrationServiceProtocol
    ) {
        self.authManager = authManager
        self.syncManager = syncManager
        self.forestManager = forestManager
        self.assetHydrationService = assetHydrationService
    }
}

extension CloudRestorePromptService: CloudRestorePromptServiceProtocol {
    
    @discardableResult
    func checkAndPromptIfNeeded() async -> CloudRestoreCheckOutcome {
        guard authManager.isUserSignedIn else { return .notSignedIn }
        
        let cloudResult = await syncManager.userHaveForest()
        let localForest = forestManager.fetchSafeForest(contextType: .main).data
        
        guard let cloudForest = cloudResult.data else {
            if let syncError = cloudResult.error as? ForestSyncError, case .noDataToSync = syncError {
                // Cloud is empty: bind and upload the local forest if there is one.
                guard localForest != nil else { return .upToDate }
                let uploadResult = await syncManager.forceOverwriteCloud()
                return uploadResult.status == .success ? .cloudLinked : .failed(uploadResult.error)
            }
            return .failed(cloudResult.error)
        }
        
        guard let localForest else {
            // Cloud has a forest but the device has none: restore directly, nothing to lose.
            let restoreResult = await syncManager.downloadAndOverwriteLocal(with: cloudForest)
            guard restoreResult.status == .success else { return .failed(restoreResult.error) }
            markFirstRewardAsClaimed()
            return .upToDate
        }
        
        // Same forest on both sides: the regular delta sync keeps them aligned.
        if localForest.forestId == cloudForest.forestId {
            return .upToDate
        }
        
        // Different forests (e.g. fresh install with persisted sign-in): the user decides.
        presentConflictPopup(localForest: localForest, cloudForest: cloudForest)
        return .conflictPrompted
    }
}

private extension CloudRestorePromptService {
    
    func presentConflictPopup(localForest: SafeForestModel, cloudForest: SafeForestModel) {
        PopupManager.shared.show { [weak self] in
            ForestConflictView(
                localForest: localForest,
                cloudForest: cloudForest,
                onResolve: { source in
                    guard let self else {
                        PopupManager.shared.dismiss()
                        return
                    }
                    Task {
                        await self.resolveConflict(keep: source, cloudForest: cloudForest)
                    }
                }
            )
        }
    }
    
    func resolveConflict(keep source: ForestSource, cloudForest: SafeForestModel) async {
        let result: Resource<Bool>
        switch source {
        case .local:
            result = await syncManager.forceOverwriteCloud()
        case .cloud:
            result = await syncManager.downloadAndOverwriteLocal(with: cloudForest)
        }
        
        // On failure the popup stays open so the user can retry.
        if result.status == .success {
            if source == .cloud {
                markFirstRewardAsClaimed()
                // The restore is already written to CoreData; asset downloads continue in the background.
                // The popup switches to progress mode: it closes normally if hydration finishes within
                // 5 s, otherwise it closes with a "will continue in the background" notice, and can be cancelled.
                presentRestoreProgressPopup()
            } else {
                PopupManager.shared.dismiss()
            }
        }
    }

    func presentRestoreProgressPopup() {
        PopupManager.shared.show { [assetHydrationService] in
            ForestRestoreProgressView(
                statePublisher: assetHydrationService.statePublisher,
                onCancel: {
                    // Cancelling does not roll the restore back: the forest stays in place, only the
                    // downloads stop and undownloaded entities remain queued (assetReady == false).
                    assetHydrationService.cancelActiveHydration()
                    PopupManager.shared.dismiss()
                },
                onFinished: {
                    PopupManager.shared.dismiss()
                }
            )
        }
    }
    
    /// A restored cloud forest belongs to an existing player, so the one-time
    /// starter animal pick must not be offered again.
    func markFirstRewardAsClaimed() {
        UserDefaults.standard.set(true, forKey: AppStorageNames.userClaimedFirtReward.rawValue)
    }
}
