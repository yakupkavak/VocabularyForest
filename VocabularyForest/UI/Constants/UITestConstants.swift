//
//  UITestConstants.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 13.08.2026.
//

import Foundation

/// Shared contract between the app and the UI test bundle. The values are duplicated in
/// `VocabularyForestUITests/StoreScreenshotTests.swift`; the test target cannot import the
/// app module, so both sides must be changed together.
enum UITestConstants {

    static let launchArgument = "-UITEST"

    /// Answer tiles are visually identical, so screenshot automation cannot tell a correct
    /// choice from a wrong one. Accessibility identifiers are inert for VoiceOver and are
    /// only published during a UI test run, so the shipped accessibility tree is unchanged.
    static let correctAnswerIdentifier = "battle_answer_correct"
    static let wrongAnswerIdentifier = "battle_answer_wrong"

    static var isUITestRun: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Empty outside UI test runs, which leaves the element's identifier untouched.
    static func answerIdentifier(isCorrect: Bool) -> String {
        guard isUITestRun else { return "" }
        return isCorrect ? correctAnswerIdentifier : wrongAnswerIdentifier
    }
}
