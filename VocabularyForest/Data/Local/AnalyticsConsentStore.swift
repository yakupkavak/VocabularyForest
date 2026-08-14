//
//  AnalyticsConsentStore.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.08.2026.
//

import Foundation

protocol AnalyticsConsentStoreProtocol: AnyObject {
    var isAnalyticsEnabled: Bool { get }
    func setAnalyticsEnabled(_ isEnabled: Bool)
}

// MARK: - CONSTANTS

private extension AnalyticsConsentStore {
    enum Constants {
        static let analyticsEnabledKey = "analyticsCollectionEnabled"
    }
}

final class AnalyticsConsentStore {

    // MARK: - PROPERTIES

    private let userDefaults: UserDefaults

    // MARK: - INIT

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension AnalyticsConsentStore: AnalyticsConsentStoreProtocol {

    /// Opt-out model: a missing value means the user has never made a choice, so collection stays
    /// on. `bool(forKey:)` alone cannot express that — it returns false for an absent key, which
    /// would silently disable analytics for every existing install on first launch after update.
    var isAnalyticsEnabled: Bool {
        userDefaults.object(forKey: Constants.analyticsEnabledKey) as? Bool ?? true
    }

    func setAnalyticsEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: Constants.analyticsEnabledKey)
    }
}
