//
//  NoopAnalyticsService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

import Foundation

/// Registered instead of `FirebaseAnalyticsService` for UI tests and previews
/// so they never pollute production analytics data.
final class NoopAnalyticsService {

    // MARK: - INIT

    init() { }
}

// MARK: - PROTOCOL CONFORMANCE

extension NoopAnalyticsService: AnalyticsServiceProtocol {

    func log(_ event: AnalyticsEvent) { }

    func logScreen(_ screen: AnalyticsScreen) { }

    func set(_ property: AnalyticsUserProperty) { }

    func setUserID(_ id: String?) { }

    func setCollectionEnabled(_ isEnabled: Bool) { }

    func updateAdConsent(isGranted: Bool) { }
}
