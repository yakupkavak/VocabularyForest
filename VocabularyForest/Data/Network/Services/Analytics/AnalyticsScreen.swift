//
//  AnalyticsScreen.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

import Foundation

// Raw values are the `screen_name` dimension in GA4 and a binding contract
// with the Android mirror — do not rename.
enum AnalyticsScreen: String, CaseIterable {
    case splash
    case onboarding
    case forest
    case battle
    case learningFeed = "learning_feed"
    case bookcaseFeed = "bookcase_feed"
    case bookcaseDetail = "bookcase_detail"
    case bookcasePackets = "bookcase_packets"
    case createBookcase = "create_bookcase"
    case createBook = "create_book"
    case editBook = "edit_book"
    case editBookcase = "edit_bookcase"
    case settings
    case market
    case adventureRoad = "adventure_road"
    case dailySpin = "daily_spin"
    case weeklyReward = "weekly_reward"
    case questList = "quest_list"
    case gameSelect = "game_select"
    case claimReward = "claim_reward"
}

// MARK: - CONSTANTS

private extension AnalyticsScreen {
    enum Constants {
        static let classNameSuffix = "UI"
        static let wordSeparator: Character = "_"
    }
}

// MARK: - HELPERS

extension AnalyticsScreen {

    /// Logical screen class reported as `screen_class`. Derived from the raw value
    /// instead of the SwiftUI type name so both platforms report identical values.
    var className: String {
        let pascalCased = rawValue
            .split(separator: Constants.wordSeparator)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
        return pascalCased + Constants.classNameSuffix
    }
}
