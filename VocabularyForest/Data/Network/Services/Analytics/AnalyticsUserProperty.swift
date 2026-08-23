//
//  AnalyticsUserProperty.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.08.2026.
//

import Foundation

struct AnalyticsUserPropertyDescriptor {
    let name: String
    let value: String?
}

enum AnalyticsUserProperty {
    case playerLevel(Int)
    case bookcaseCount(Int)
    case wordCount(Int)
    case hasCloudAccount(Bool)
    case notificationsEnabled(Bool)
    case learningLanguagePair(String)
    case appLanguage(String)
}

// MARK: - CONSTANTS

private extension AnalyticsUserProperty {
    enum Constants {
        // Property names — GA4 limit: name ≤24 chars, value ≤36 chars.
        static let playerLevel = "player_level"
        static let bookcaseCount = "bookcase_count"
        static let wordCountBucket = "word_count_bucket"
        static let hasCloudAccount = "has_cloud_account"
        static let notificationsEnabled = "notifications_enabled"
        static let learningLanguagePair = "learning_language_pair"
        static let appLanguage = "app_language"
        // Counts are reported as buckets: raw numbers make GA4 dimensions unusable
        // because every distinct value becomes its own report row.
        static let bookcaseBuckets: [(range: ClosedRange<Int>, label: String)] = [
            (0...0, "0"), (1...2, "1-2"), (3...5, "3-5")
        ]
        static let bookcaseOverflowLabel = "6+"
        static let wordBuckets: [(range: ClosedRange<Int>, label: String)] = [
            (0...9, "0-9"), (10...49, "10-49"), (50...199, "50-199")
        ]
        static let wordOverflowLabel = "200+"
    }
}

// MARK: - HELPERS

extension AnalyticsUserProperty {

    var descriptor: AnalyticsUserPropertyDescriptor {
        switch self {
        case let .playerLevel(level):
            return AnalyticsUserPropertyDescriptor(name: Constants.playerLevel, value: String(level))
        case let .bookcaseCount(count):
            return AnalyticsUserPropertyDescriptor(
                name: Constants.bookcaseCount,
                value: Self.bucketLabel(for: count, buckets: Constants.bookcaseBuckets, overflow: Constants.bookcaseOverflowLabel)
            )
        case let .wordCount(count):
            return AnalyticsUserPropertyDescriptor(
                name: Constants.wordCountBucket,
                value: Self.bucketLabel(for: count, buckets: Constants.wordBuckets, overflow: Constants.wordOverflowLabel)
            )
        case let .hasCloudAccount(hasAccount):
            return AnalyticsUserPropertyDescriptor(name: Constants.hasCloudAccount, value: String(hasAccount))
        case let .notificationsEnabled(isEnabled):
            return AnalyticsUserPropertyDescriptor(name: Constants.notificationsEnabled, value: String(isEnabled))
        case let .learningLanguagePair(pair):
            return AnalyticsUserPropertyDescriptor(name: Constants.learningLanguagePair, value: pair)
        case let .appLanguage(language):
            return AnalyticsUserPropertyDescriptor(name: Constants.appLanguage, value: language)
        }
    }
}

// MARK: - PRIVATE HELPERS

private extension AnalyticsUserProperty {

    static func bucketLabel(for count: Int, buckets: [(range: ClosedRange<Int>, label: String)], overflow: String) -> String {
        buckets.first { $0.range.contains(count) }?.label ?? overflow
    }
}
