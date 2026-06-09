//
//  MockRewardRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.06.2026.
//

@testable import VocabularyForest
import Testing

class MockRewardRepository {
    var processCallCount = 0
    var claimCallCount = 0
    var lastProcessedRemoteReward: RemoteRewardModel?
    var lastClaimedReward: LocalRewardModel?
    var processReturnValue: LocalRewardModel!
    var errorToThrow: Error?
}

extension MockRewardRepository: RewardRepositoryProtocol {
    func processAndGetLocalReward(from remoteReward: VocabularyForest.RemoteRewardModel) async throws -> VocabularyForest.LocalRewardModel {
        processCallCount += 1
        lastProcessedRemoteReward = remoteReward
        if let error = errorToThrow {
            throw error
        }
        return processReturnValue
    }
    
    func claimLocalReward(reward: VocabularyForest.LocalRewardModel) async throws {
        claimCallCount += 1
        lastClaimedReward = reward
        
        if let error = errorToThrow {
            throw error
        }
    }
}
