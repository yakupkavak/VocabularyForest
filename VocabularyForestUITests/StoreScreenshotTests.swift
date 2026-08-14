//
//  StoreScreenshotTests.swift
//  VocabularyForestUITests
//
//  Created by Yakup Kavak on 13.08.2026.
//

import XCTest

// MARK: - CONSTANTS

private enum Constants {

    // Mirrors `UITestConstants` in the app target, which the test bundle cannot import.
    static let launchArgument = "-UITEST"
    static let correctAnswerIdentifier = "battle_answer_correct"
    static let wrongAnswerIdentifier = "battle_answer_wrong"

    static let launchTimeout: TimeInterval = 180
    static let uiTimeout: TimeInterval = 60
    static let sceneTimeout: TimeInterval = 90
    static let questionTimeout: TimeInterval = 60

    /// Easy classic needs 4 correct answers before the magic popup interrupts the round and
    /// 3 wrong ones before the enemy attacks, so 3 + 1 stays inside a single question flow.
    static let correctAnswerCount = 3

    static let maxSwipes = 40
    static let maxAlignmentSteps = 8
    /// A row is considered flush with the top of the list within this many points.
    static let alignmentTolerance: CGFloat = 4
    /// Rows carry 16pt of empty padding below their card, so stopping a few points short of the
    /// list's top edge hides the previous row completely without clipping this row's animal.
    static let topRowInset: CGFloat = 4
    /// Longer drags overshoot the screen bounds, so tall corrections are split into steps.
    static let maxDragDistance: CGFloat = 280

    static let settleDelay: TimeInterval = 1.5
    static let animationDelay: TimeInterval = 3.0
}

// MARK: - CONFIGURATION

/// Values the host script computes per language and forwards with the `TEST_RUNNER_` prefix.
private struct ScreenshotConfig {

    let language: String
    let locale: String
    let b1BookcaseName: String
    let a2BookcaseName: String
    /// `"<learning language> / <meaning language>"` exactly as `BookcaseRow` renders it, used to
    /// tell apart bookcases that share a name across languages (Spanish/Italian "B1 - Intermedio").
    let b1LanguageLine: String
    let a2LanguageLine: String
    let enterForestLabel: String
    let playGameLabel: String
    let adventureBoardLabel: String
    let adventureRoadLabel: String
    let selectBookcaseButtonLabel: String
    let startGameLabel: String
    let selectBookcaseIconLabel: String
    /// Screenshots to capture. Empty means every one.
    let requestedShots: Set<String>

    func wants(_ shot: String) -> Bool {
        requestedShots.isEmpty || requestedShots.contains(shot)
    }

    static func fromEnvironment() throws -> ScreenshotConfig {
        let environment = ProcessInfo.processInfo.environment
        func value(_ key: String) throws -> String {
            guard let value = environment[key], !value.isEmpty else {
                throw XCTSkip("Missing environment value for \(key)")
            }
            return value
        }
        return ScreenshotConfig(
            language: try value("SHOT_LANGUAGE"),
            locale: try value("SHOT_LOCALE"),
            b1BookcaseName: try value("SHOT_B1_NAME"),
            a2BookcaseName: try value("SHOT_A2_NAME"),
            b1LanguageLine: try value("SHOT_B1_LANGUAGE_LINE"),
            a2LanguageLine: try value("SHOT_A2_LANGUAGE_LINE"),
            enterForestLabel: try value("SHOT_ENTER_FOREST"),
            playGameLabel: try value("SHOT_PLAY_GAME"),
            adventureBoardLabel: try value("SHOT_ADVENTURE_BOARD"),
            adventureRoadLabel: try value("SHOT_ADVENTURE_ROAD"),
            selectBookcaseButtonLabel: try value("SHOT_SELECT_BOOKCASE_BUTTON"),
            startGameLabel: try value("SHOT_START_GAME"),
            selectBookcaseIconLabel: try value("SHOT_SELECT_BOOKCASE_ICON"),
            requestedShots: Set(
                (environment["SHOT_ONLY"] ?? "")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            )
        )
    }
}

// MARK: - TESTS

final class StoreScreenshotTests: XCTestCase {

    private var app: XCUIApplication!
    private var config: ScreenshotConfig!

    override func setUpWithError() throws {
        continueAfterFailure = false
        config = try ScreenshotConfig.fromEnvironment()
        app = XCUIApplication()
        app.launchArguments = [
            Constants.launchArgument,
            "-AppleLanguages", "(\(config.language))",
            "-AppleLocale", config.locale
        ]
    }

    func testCaptureStoreScreenshots() throws {
        if config.wants("01_game") { try captureGame() }
        if config.wants("02_adventure_road") { try captureAdventureRoad() }
        if config.wants("03_add_word") { try captureAddWord() }
        if config.wants("04_bookcases") { try captureBookcaseList() }
    }
}

// MARK: - SCREENSHOT STEPS

private extension StoreScreenshotTests {

    /// Classic / Easy / Learning are the game popup's defaults, so only the bookcase is chosen.
    func captureGame() throws {
        relaunch()
        try openForest()

        let playGame = button(containing: config.playGameLabel)
        XCTAssertTrue(playGame.waitForExistence(timeout: Constants.sceneTimeout), "Forest menu never appeared")
        playGame.tap()

        let selectBookcase = button(containing: config.selectBookcaseButtonLabel)
        XCTAssertTrue(selectBookcase.waitForExistence(timeout: Constants.uiTimeout), "Game popup never appeared")
        selectBookcase.tap()

        try pickBookcaseInSheet(name: config.b1BookcaseName, languageLine: config.b1LanguageLine)

        let startGame = button(containing: config.startGameLabel)
        XCTAssertTrue(startGame.waitForExistence(timeout: Constants.uiTimeout), "Start game button missing")
        startGame.tap()

        for _ in 0..<Constants.correctAnswerCount {
            try answerQuestion(identifier: Constants.correctAnswerIdentifier)
        }
        try answerQuestion(identifier: Constants.wrongAnswerIdentifier)

        // The battle screen must be back on a question before the shot is worth keeping.
        let nextQuestion = answerElements(identifier: Constants.correctAnswerIdentifier).firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: Constants.questionTimeout), "Battle never returned to a question")
        wait(Constants.animationDelay)
        capture(named: "01_game")
    }

    func captureAdventureRoad() throws {
        relaunch()
        try openForest()

        let adventureBoard = button(containing: config.adventureBoardLabel)
        XCTAssertTrue(adventureBoard.waitForExistence(timeout: Constants.sceneTimeout), "Forest menu never appeared")
        adventureBoard.tap()

        let adventureRoad = button(containing: config.adventureRoadLabel)
        XCTAssertTrue(adventureRoad.waitForExistence(timeout: Constants.uiTimeout), "Adventure board never appeared")
        adventureRoad.tap()

        // The road renders a ProgressView until its remote config and reward art resolve.
        let loaded = waitUntil(timeout: Constants.sceneTimeout) { [self] in
            app.scrollViews.firstMatch.exists && !app.activityIndicators.firstMatch.exists
        }
        XCTAssertTrue(loaded, "Adventure road never finished loading")
        wait(Constants.animationDelay)
        // Captured at its initial offset: the road must be shown from the very top.
        capture(named: "02_adventure_road")
    }

    func captureAddWord() throws {
        relaunch()
        selectTab(1)

        let selectBookcase = button(containing: config.selectBookcaseIconLabel)
        XCTAssertTrue(selectBookcase.waitForExistence(timeout: Constants.uiTimeout), "Add word screen never appeared")
        selectBookcase.tap()

        try pickBookcaseInSheet(name: config.b1BookcaseName, languageLine: config.b1LanguageLine)

        wait(Constants.settleDelay)
        capture(named: "03_add_word")
    }

    func captureBookcaseList() throws {
        relaunch()
        selectTab(2)

        let list = try scrollContainer()
        XCTAssertTrue(list.waitForExistence(timeout: Constants.uiTimeout), "Bookcase list never appeared")
        wait(Constants.settleDelay)

        let row = try scrollToRow(
            name: config.a2BookcaseName,
            languageLine: config.a2LanguageLine,
            in: list
        )
        // The row's animal head sits inside the row bounds at its very top, so landing the row on
        // the first row's resting position keeps the animal from being clipped.
        alignToTop(row, in: list)
        wait(Constants.settleDelay)
        capture(named: "04_bookcases")
    }
}

// MARK: - NAVIGATION HELPERS

private extension StoreScreenshotTests {

    func relaunch() {
        app.terminate()
        app.launch()
        XCTAssertTrue(tabButton(at: 0).waitForExistence(timeout: Constants.launchTimeout), "Tab bar never appeared")
        // The tab bar exists before the splash finishes handing over, and taps sent during that
        // transition are dropped, so the first interaction waits the animation out.
        wait(Constants.settleDelay)
        dismissSystemAlertIfNeeded()
    }

    /// SwiftUI wraps interpolated localized strings in Unicode bidi isolates (U+2068/U+2069),
    /// so a label that reads "اختر خزانة الكتب" on screen is "⁨اختر خزانة الكتب⁩" in the tree and
    /// never matches by equality. Substring matching is immune to the wrapper.
    func button(containing label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
    }

    func tabButton(at index: Int) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: index)
    }

    /// Taps until the tab actually reports itself selected; a single tap is not reliable here.
    func selectTab(_ index: Int) {
        let tab = tabButton(at: index)
        XCTAssertTrue(tab.waitForExistence(timeout: Constants.uiTimeout), "Tab \(index) missing")
        for _ in 0..<5 {
            if tab.isSelected { return }
            tab.tap()
            if waitUntil(timeout: 5, condition: { tab.isSelected }) { return }
        }
        XCTFail("Tab \(index) never became selected")
    }

    func openForest() throws {
        selectTab(0)
        let row = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", config.enterForestLabel)
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: Constants.uiTimeout), "Forest entry row missing")
        row.tap()
    }

    /// Taps the answer tile carrying `identifier` and waits for the next question to be drawn.
    func answerQuestion(identifier: String) throws {
        let correctTile = answerElements(identifier: Constants.correctAnswerIdentifier).firstMatch
        XCTAssertTrue(correctTile.waitForExistence(timeout: Constants.questionTimeout), "No question on screen")
        // The correct answer's text identifies the current question. Waiting for it to change is
        // more reliable than watching the tiles disappear, which lasts barely a second.
        let currentQuestion = correctTile.label

        let tile = answerElements(identifier: identifier).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: Constants.questionTimeout), "No answer tile for \(identifier)")
        XCTAssertTrue(waitUntil(timeout: Constants.uiTimeout) { tile.isHittable }, "Answer tile not hittable")
        tile.tap()

        let advanced = waitUntil(timeout: Constants.questionTimeout) { [self] in
            let next = answerElements(identifier: Constants.correctAnswerIdentifier).firstMatch
            return next.exists && next.label != currentQuestion
        }
        XCTAssertTrue(advanced, "Battle never advanced to the next question")
    }

    func answerElements(identifier: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: identifier)
    }

    /// Searching the exact name leaves at most two rows (a few names repeat across languages),
    /// so the wanted row is always on screen and the picker never has to be scrolled.
    func pickBookcaseInSheet(name: String, languageLine: String) throws {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: Constants.uiTimeout), "Bookcase picker never appeared")
        searchField.tap()
        searchField.typeText(name)
        wait(Constants.settleDelay)

        let row = bookcaseRow(name: name, languageLine: languageLine)
        XCTAssertTrue(row.waitForExistence(timeout: Constants.uiTimeout), "Bookcase '\(name)' not in picker")
        row.tap()
        // The sheet dismisses itself once a bookcase is chosen.
        _ = waitUntil(timeout: Constants.uiTimeout) { !searchField.exists }
        wait(Constants.settleDelay)
    }

    /// Rows carry the bookcase name followed by its language line, so the strict predicate picks
    /// the right one when two languages share a name ("B1 - Intermedio" is Spanish and Italian).
    func bookcaseRow(name: String, languageLine: String) -> XCUIElement {
        let strict = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", name, languageLine)
        ).firstMatch
        if strict.exists { return strict }
        // RTL layouts can reorder the two language names, so fall back to the learning side alone.
        // Both predicates still exclude the header button, whose label is the bookcase name only.
        let learning = languageLine.components(separatedBy: " / ").first ?? languageLine
        return app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", name, learning)
        ).firstMatch
    }

    func dismissSystemAlertIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        guard springboard.alerts.firstMatch.exists else { return }
        // The leading button is the declining one on system prompts ("Ask App Not to Track",
        // "Don't Allow"), which keeps the run from granting permissions on the user's behalf.
        let button = springboard.alerts.firstMatch.buttons.element(boundBy: 0)
        if button.exists { button.tap() }
    }
}

// MARK: - SCROLLING HELPERS

private extension StoreScreenshotTests {

    /// SwiftUI renders `List` as a collection view on iOS 16+, but sheets and plain scroll views
    /// still surface as other container types.
    func scrollContainer() throws -> XCUIElement {
        for query in [app.collectionViews, app.tables, app.scrollViews] {
            let candidate = query.firstMatch
            if candidate.waitForExistence(timeout: Constants.settleDelay) { return candidate }
        }
        throw XCTSkip("No scrollable container on screen")
    }

    /// Rows are lazily realised, so the feed is swiped until the wanted one enters the tree.
    /// One swipe advances roughly three rows; the whole feed is 60 rows deep.
    func scrollToRow(name: String, languageLine: String, in container: XCUIElement) throws -> XCUIElement {
        for attempt in 0...Constants.maxSwipes {
            let row = bookcaseRow(name: name, languageLine: languageLine)
            if row.exists { return row }
            if attempt < Constants.maxSwipes { container.swipeUp() }
        }
        XCTFail("Bookcase row '\(name)' (\(languageLine)) never came into view")
        throw XCTSkip("Row not found")
    }

    /// Drags the list until `element` sits flush with the top of the visible list area, so the
    /// row above is scrolled fully out of frame. The row's animal head is the topmost thing
    /// inside the row's own bounds, so landing there shows it whole rather than clipping it.
    func alignToTop(_ element: XCUIElement, in container: XCUIElement) {
        let target = container.frame.minY + Constants.topRowInset
        for _ in 0..<Constants.maxAlignmentSteps {
            let delta = element.frame.minY - target
            guard abs(delta) > Constants.alignmentTolerance else { return }

            let step = min(abs(delta), Constants.maxDragDistance) * (delta < 0 ? -1 : 1)
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: 0, dy: -step))
            // A slow drag held at the end lands without the momentum a swipe would add.
            start.press(forDuration: 0.2, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.4)
            wait(Constants.settleDelay)
        }
    }

}

// MARK: - CAPTURE HELPERS

private extension StoreScreenshotTests {

    func capture(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func wait(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return condition()
    }
}
