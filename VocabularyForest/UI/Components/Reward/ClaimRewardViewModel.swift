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
    
    // MARK: - PROPERTIES
    
    @Published var errorMessage: String?
    @Published var chestRewards: [LocalRewardModel]? = nil
    
    // MARK: INIT
    
    init(chestManager: ChestRepositoryProtocol) {
        self.chestManager = chestManager
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
}
