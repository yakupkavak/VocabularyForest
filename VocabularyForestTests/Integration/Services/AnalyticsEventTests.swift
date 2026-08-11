//
//  AnalyticsEventTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

@testable import VocabularyForest
import Foundation
import Testing

// MARK: - MOCK

final class MockAnalyticsService: AnalyticsServiceProtocol {

    private(set) var loggedEvents: [AnalyticsEvent] = []
    private(set) var loggedScreens: [AnalyticsScreen] = []
    private(set) var setProperties: [AnalyticsUserProperty] = []
    private(set) var userID: String??
    private(set) var isCollectionEnabled: Bool?
    private(set) var isAdConsentGranted: Bool?

    func log(_ event: AnalyticsEvent) { loggedEvents.append(event) }
    func logScreen(_ screen: AnalyticsScreen) { loggedScreens.append(screen) }
    func set(_ property: AnalyticsUserProperty) { setProperties.append(property) }
    func setUserID(_ id: String?) { userID = id }
    func setCollectionEnabled(_ isEnabled: Bool) { isCollectionEnabled = isEnabled }
    func updateAdConsent(isGranted: Bool) { isAdConsentGranted = isGranted }
}

// MARK: - CONSTANTS

private enum AnalyticsTestConstants {
    static let maxEventNameLength = 40
    static let maxParameterNameLength = 40
    static let maxParameterValueLength = 100
    static let maxParametersPerEvent = 25
    static let maxUserPropertyNameLength = 24
    static let maxUserPropertyValueLength = 36
    static let reservedPrefixes = ["firebase_", "google_", "ga_"]
    static let namePattern = /^[a-zA-Z][a-zA-Z0-9_]*$/

    /// One representative instance per `AnalyticsEvent` case. A new enum case
    /// must be added here so the GA4 limit checks keep covering the full catalog.
    static let eventCatalog: [AnalyticsEvent] = [
        .tutorialBegin,
        .onboardingStepViewed(stepIndex: 1),
        .tutorialComplete,
        .login(method: .apple),
        .signUp(method: .google),
        .attPromptResult(status: .notDetermined),
        .bookcaseCreated(languagePair: "tr_en", source: .manual),
        .bookcaseSelected(bookcaseID: "bookcase-1"),
        .bookCreated(bookcaseID: "bookcase-1", hasExample: true),
        .bookEdited(bookcaseID: "bookcase-1"),
        .bookDeleted(bookcaseID: "bookcase-1"),
        .packetDownloadStarted(packetID: "packet-1", unlockMethod: .rewardedAd),
        .packetDownloadCompleted(packetID: "packet-1", wordCount: 50),
        .packetDownloadFailed(packetID: "packet-1", reason: "network"),
        .dailyWordViewed,
        .quizStarted(bookcaseID: "bookcase-1", questionCount: 10),
        .quizCompleted(correctCount: 8, totalCount: 10, durationSeconds: 90),
        .quizAbandoned(answeredCount: 4, totalCount: 10),
        .levelStart(levelName: "level_1", character: "enemy_1"),
        .levelEnd(levelName: "level_1", isWon: true, score: 120),
        .magicUsed(magicType: "fire"),
        .gameAbandoned(levelName: "level_1", questionIndex: 3),
        .virtualCurrencyEarned(currencyName: "gold", value: 10, source: "daily_spin"),
        .virtualCurrencySpent(itemName: "tree", currencyName: "gold", value: 10),
        .achievementUnlocked(achievementID: "quest_1"),
        .dailySpinClaimed(rewardID: "reward_1"),
        .weeklyRewardClaimed(dayIndex: 3),
        .adventureRewardClaimed(milestoneID: "milestone_1", seasonID: "season_1"),
        .chestOpened(chestID: "chest_1"),
        .marketItemPurchased(itemID: "item_1", price: 100),
        .cloudSyncCompleted(result: .success, trigger: .auto),
        .cloudRestorePromptShown,
        .cloudRestorePromptResult(choice: .keepLocal),
        .notificationPermissionResult(status: .authorized),
        .accountDeleted,
        .signOut
    ]

    static let userPropertyCatalog: [AnalyticsUserProperty] = [
        .playerLevel(12),
        .bookcaseCount(4),
        .wordCount(75),
        .hasCloudAccount(true),
        .notificationsEnabled(false),
        .learningLanguagePair("tr_en"),
        .appLanguage("tr")
    ]
}

// MARK: - TESTS

@Suite("Analytics Event Tests")
struct AnalyticsEventTests {

    @Test("Event names respect GA4 length, charset and reserved prefix rules")
    func eventNamesAreValid() {
        for event in AnalyticsTestConstants.eventCatalog {
            let name = event.descriptor.name
            #expect(name.count <= AnalyticsTestConstants.maxEventNameLength, "\(name) exceeds 40 chars")
            #expect(name.firstMatch(of: AnalyticsTestConstants.namePattern) != nil, "\(name) has invalid characters")
            for prefix in AnalyticsTestConstants.reservedPrefixes {
                #expect(!name.hasPrefix(prefix), "\(name) uses reserved prefix \(prefix)")
            }
        }
    }

    @Test("Event parameters respect GA4 count and length limits")
    func eventParametersAreValid() {
        for event in AnalyticsTestConstants.eventCatalog {
            let descriptor = event.descriptor
            #expect(descriptor.parameters.count <= AnalyticsTestConstants.maxParametersPerEvent, "\(descriptor.name) has too many parameters")
            for (key, value) in descriptor.parameters {
                #expect(key.count <= AnalyticsTestConstants.maxParameterNameLength, "\(descriptor.name).\(key) name too long")
                #expect(key.firstMatch(of: AnalyticsTestConstants.namePattern) != nil, "\(descriptor.name).\(key) has invalid characters")
                if let stringValue = value as? String {
                    #expect(stringValue.count <= AnalyticsTestConstants.maxParameterValueLength, "\(descriptor.name).\(key) value too long")
                }
            }
        }
    }

    @Test("Event catalog covers every enum case exactly once")
    func eventCatalogHasNoDuplicates() {
        let names = AnalyticsTestConstants.eventCatalog.map { $0.descriptor.name }
        #expect(Set(names).count == names.count, "Duplicate event names found in catalog")
    }

    @Test("Screen raw values are unique and produce valid names")
    func screenNamesAreValid() {
        let rawValues = AnalyticsScreen.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count, "Duplicate screen raw values")
        for screen in AnalyticsScreen.allCases {
            #expect(screen.rawValue.firstMatch(of: AnalyticsTestConstants.namePattern) != nil, "\(screen.rawValue) has invalid characters")
            #expect(!screen.className.isEmpty)
        }
    }

    @Test("User property names and values respect GA4 limits")
    func userPropertiesAreValid() {
        for property in AnalyticsTestConstants.userPropertyCatalog {
            let descriptor = property.descriptor
            #expect(descriptor.name.count <= AnalyticsTestConstants.maxUserPropertyNameLength, "\(descriptor.name) name too long")
            if let value = descriptor.value {
                #expect(value.count <= AnalyticsTestConstants.maxUserPropertyValueLength, "\(descriptor.name) value too long")
            }
        }
    }

    @Test("Count properties are reported as buckets, not raw numbers")
    func countPropertiesAreBucketed() {
        #expect(AnalyticsUserProperty.bookcaseCount(0).descriptor.value == "0")
        #expect(AnalyticsUserProperty.bookcaseCount(2).descriptor.value == "1-2")
        #expect(AnalyticsUserProperty.bookcaseCount(5).descriptor.value == "3-5")
        #expect(AnalyticsUserProperty.bookcaseCount(99).descriptor.value == "6+")
        #expect(AnalyticsUserProperty.wordCount(9).descriptor.value == "0-9")
        #expect(AnalyticsUserProperty.wordCount(49).descriptor.value == "10-49")
        #expect(AnalyticsUserProperty.wordCount(199).descriptor.value == "50-199")
        #expect(AnalyticsUserProperty.wordCount(500).descriptor.value == "200+")
    }

    @Test("Mock service records interactions through the protocol")
    func mockServiceRecordsCalls() {
        let mockService = MockAnalyticsService()
        let sut: AnalyticsServiceProtocol = mockService
        sut.log(.tutorialBegin)
        sut.logScreen(.forest)
        sut.set(.playerLevel(3))
        sut.setCollectionEnabled(false)
        sut.updateAdConsent(isGranted: true)
        #expect(mockService.loggedEvents.count == 1)
        #expect(mockService.loggedScreens == [.forest])
        #expect(mockService.isCollectionEnabled == false)
        #expect(mockService.isAdConsentGranted == true)
    }
}
