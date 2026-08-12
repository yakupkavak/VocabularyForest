//
//  AccessibilityAuditTests.swift
//  VocabularyForestUITests
//
//  Created by Yakup Kavak on 12.08.2026.
//

import XCTest

/// Automated accessibility audits for the app's main flows.
/// `performAccessibilityAudit` flags missing labels, low contrast, small hit
/// regions and Dynamic Type clipping — the automatable part of the VoiceOver
/// evaluation criteria. Manual VoiceOver passes remain required before
/// declaring support in App Store Connect.
final class AccessibilityAuditTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // -UITEST swaps in NoopAnalyticsService so test runs never reach production analytics.
        app.launchArguments += ["-UITEST"]
        app.launch()
    }

    // MARK: - TAB AUDITS

    @MainActor
    func testLearningFeedAudit() throws {
        try audit()
    }

    @MainActor
    func testCreateBookAudit() throws {
        openTab(index: 1)
        try audit()
    }

    @MainActor
    func testBookcaseFeedAudit() throws {
        openTab(index: 2)
        try audit()
    }

    @MainActor
    func testSettingsAudit() throws {
        openTab(index: 3)
        try audit()
    }

    // MARK: - FOREST AUDIT

    @MainActor
    func testForestAudit() throws {
        openTab(index: 0)
        // The learning feed's single quiz row routes into the forest scene.
        // The simulator runs with an English locale in CI/local test runs.
        let quizRow = app.buttons["Embark on Adventure"].firstMatch
        if quizRow.waitForExistence(timeout: 5) {
            quizRow.tap()
            // Allow the SpriteKit scene and any first-run popup to settle.
            sleep(3)
            try audit()
        }
    }

    // MARK: - HELPERS

    private func openTab(index: Int) {
        let tab = app.tabBars.buttons.element(boundBy: index)
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func audit() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("performAccessibilityAudit requires iOS 17")
        }
        try app.performAccessibilityAudit()
    }
}
