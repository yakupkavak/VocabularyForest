//
//  VocabularyForestApp.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import CoreData
import DependencyContainer
import GoogleMobileAds
import AppTrackingTransparency
import FirebaseCore

@main
struct VocabularyForestApp: App {
    
    // MARK: - PROPERTIES
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var routerLearning = LearningRouter()
    @StateObject private var routerBookcase = BookcaseRouter()
    @StateObject private var routerCreateBookcase = CreateBookRouter()
    @StateObject private var tabbarController = TabBarController()
    @StateObject private var coordinator: VocabularyForestCoordinator
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - INIT

    init() {
        FirebaseApp.configure()
        AppDependencyConfigurer.configure()
        let resolver = DC.shared
        _coordinator = StateObject(wrappedValue: VocabularyForestCoordinator(resolver: resolver))
        analyticsService = resolver.resolve(type: .singleInstance, for: AnalyticsServiceProtocol.self)
        // Consent must reflect the stored ATT status before the first events are sent.
        analyticsService.updateAdConsent(isGranted: ATTrackingManager.trackingAuthorizationStatus == .authorized)
        if let appLanguage = Locale.current.language.languageCode?.identifier {
            analyticsService.set(.appLanguage(appLanguage))
        }
    }
    
    // MARK: - VIEWS
    
    var body: some Scene {
        WindowGroup {
            coordinator.startSplashUI().background(.backgroundSystem).onChange(of: scenePhase) { phase in
                let rewardNotificationService = DC.shared.resolve(type: .singleInstance, for: RewardNotificationServiceProtocol.self)
                if phase == .background {
                    let coreDataManager = DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
                    coreDataManager.save(type: .main)
                    Task {
                        await rewardNotificationService.scheduleRewardNotifications()
                    }
                } else if phase == .active {
                    rewardNotificationService.cancelRewardNotifications()
                    requestTrackingThenStartAds()
                }
            }.environmentObject(routerBookcase).environmentObject(routerCreateBookcase).environmentObject(routerLearning)
                .environmentObject(tabbarController).environmentObject(coordinator)
                .installToast(position: .bottom)
                .withGlobalPopup()
                .environment(\.analyticsService, analyticsService)
        }
    }
}

// MARK: - HELPERS

private extension VocabularyForestApp {

    /// Google recommends requesting ATT before the Mobile Ads SDK starts so the
    /// first ad requests can carry the IDFA. The system only prompts once; on
    /// later activations the completion fires immediately with the stored status.
    func requestTrackingThenStartAds() {
        let isFirstPrompt = ATTrackingManager.trackingAuthorizationStatus == .notDetermined
        ATTrackingManager.requestTrackingAuthorization { status in
            analyticsService.updateAdConsent(isGranted: status == .authorized)
            if isFirstPrompt {
                analyticsService.log(.attPromptResult(status: status.analyticsStatus))
            }
            DispatchQueue.main.async {
                MobileAds.shared.start(completionHandler: nil)
            }
        }
    }
}

private extension ATTrackingManager.AuthorizationStatus {

    var analyticsStatus: AnalyticsTrackingStatus {
        switch self {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}
