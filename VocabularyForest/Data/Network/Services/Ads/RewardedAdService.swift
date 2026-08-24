//
//  RewardedAdService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import Foundation

protocol RewardedAdServiceProtocol: AnyObject {
    /// Presents a rewarded ad and reports on the main thread whether the user earned the reward.
    func showRewardedAd(completion: @escaping (Bool) -> Void)
}

/// Stand-in used until an ad SDK is integrated: it always grants the reward
/// immediately so ad-gated features stay functional. Swapping in a real SDK
/// only requires registering another implementation of the protocol.
final class InstantGrantRewardedAdService {

    // MARK: - INIT

    init() { }
}

// MARK: - PROTOCOL CONFORMANCE

extension InstantGrantRewardedAdService: RewardedAdServiceProtocol {

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completion(true)
        }
    }
}
