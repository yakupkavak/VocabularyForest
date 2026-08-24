//
//  ClaimRewardViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.07.2026.
//

import Combine
import Foundation

// MARK: - CONSTANTS

private extension ClaimRewardViewModel {
    enum Constants {
        /// Bundled placeholder fanfares — replace the files keeping these names
        /// (mp3 takes precedence over the mock m4a when both exist).
        static let sTierSoundName = "s_tier_fanfare"
        static let sPlusSoundName = "s_plus_celebration"
    }
}

class ClaimRewardViewModel: ObservableObject {

    // MARK: - DEPENDENCIES

    private let chestManager: ChestRepositoryProtocol
    private let audioService: AudioServiceProtocol

    // MARK: - PROPERTIES

    @Published var errorMessage: String?
    @Published var chestRewards: [LocalRewardModel]? = nil

    // MARK: INIT

    init(chestManager: ChestRepositoryProtocol, audioService: AudioServiceProtocol) {
        self.chestManager = chestManager
        self.audioService = audioService
    }

    func openChest(chestID: String){
        Task {
            do {
                let rewards = try await chestManager.openChest(chestId: chestID)
                // @Published must be mutated on the main thread; this Task runs off-main
                await MainActor.run { chestRewards = rewards }
            }catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }

    func playCelebrationSound(tier: RewardTier) {
        guard tier.isCelebrated else { return }
        audioService.playSFX(filename: tier == .sPlus ? Constants.sPlusSoundName : Constants.sTierSoundName)
    }
}
