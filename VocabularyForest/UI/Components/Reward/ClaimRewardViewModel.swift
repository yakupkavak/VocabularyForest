//
//  ClaimRewardViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.07.2026.
//

import Combine
import Foundation

class ClaimRewardViewModel: ObservableObject {
    
    // MARK: - DEPENDENCIES
    
    private let chestManager: ChestRepositoryProtocol
    private let rewardRepository: RewardRepositoryProtocol
    
    // MARK: - PROPERTIES
    
    @Published var errorMessage: String?
    @Published var chestRewards: [LocalRewardModel]? = nil
    
    // MARK: INIT
    
    init(chestManager: ChestRepositoryProtocol, rewardRepository: RewardRepositoryProtocol) {
        self.chestManager = chestManager
        self.rewardRepository = rewardRepository
    }

    func openChest(chestID: String){
        Task {
            do {
                let rewards = try await chestManager.openChest(chestId: chestID)
                chestRewards = rewards
            }catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func claimRewards() {
        Task {
            do {
                if let chestRewards {
                    for reward in chestRewards {
                        try await rewardRepository.claimLocalReward(reward: reward)
                    }
                }
            }catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
