//
//  AnalyticsService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

import FirebaseAnalytics
import Foundation

protocol AnalyticsServiceProtocol: AnyObject {
    func log(_ event: AnalyticsEvent)
    func logScreen(_ screen: AnalyticsScreen)
    func set(_ property: AnalyticsUserProperty)
    func setUserID(_ id: String?)
    func setCollectionEnabled(_ isEnabled: Bool)
    func updateAdConsent(isGranted: Bool)
}

final class FirebaseAnalyticsService {

    // MARK: - PROPERTIES

    private let logger: AppLoggerProtocol

    // MARK: - INIT

    init(logger: AppLoggerProtocol) {
        self.logger = logger
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension FirebaseAnalyticsService: AnalyticsServiceProtocol {

    func log(_ event: AnalyticsEvent) {
        let descriptor = event.descriptor
        Analytics.logEvent(descriptor.name, parameters: descriptor.parameters)
        #if DEBUG
        logger.debug("event=\(descriptor.name) params=\(descriptor.parameters)", category: .analytics)
        #endif
    }

    func logScreen(_ screen: AnalyticsScreen) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: screen.className
        ])
        #if DEBUG
        logger.debug("screen=\(screen.rawValue)", category: .analytics)
        #endif
    }

    func set(_ property: AnalyticsUserProperty) {
        let descriptor = property.descriptor
        Analytics.setUserProperty(descriptor.value, forName: descriptor.name)
    }

    func setUserID(_ id: String?) {
        Analytics.setUserID(id)
    }

    func setCollectionEnabled(_ isEnabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
    }

    func updateAdConsent(isGranted: Bool) {
        // Analytics storage stays granted independently of ATT: the ATT prompt
        // governs cross-app tracking (IDFA), not first-party analytics.
        let adConsent: ConsentStatus = isGranted ? .granted : .denied
        Analytics.setConsent([
            .analyticsStorage: .granted,
            .adStorage: adConsent,
            .adUserData: adConsent,
            .adPersonalization: adConsent
        ])
    }
}
