//
//  AdventureRoadModels.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.04.2026.
//

import SwiftUI

// MARK: - ENUMS

enum AdventureTicketNotchSide {
    case left
    case right
} 

/// Season theme colors driven by the remote config, falls back to the default forest palette
struct AdventureRoadThemeModel {
    let backgroundTopColor: Color
    let backgroundBottomColor: Color
    let titleTextColor: Color
    let subtitleTextColor: Color
    let countdownTextColor: Color
    let countdownBackgroundColor: Color
    let wordLabelTextColor: Color
    let shortBadgeTopColor: Color
    let shortBadgeBottomColor: Color
    let shortBadgeTextColor: Color
    let longBadgeTopColor: Color
    let longBadgeBottomColor: Color
    let longBadgeTextColor: Color

    static let `default` = AdventureRoadThemeModel(
        backgroundTopColor: Color(red: 0.74, green: 0.88, blue: 0.55),
        backgroundBottomColor: Color(red: 0.16, green: 0.56, blue: 0.33),
        titleTextColor: .white,
        subtitleTextColor: .white,
        countdownTextColor: .white,
        countdownBackgroundColor: Color.black.opacity(0.14),
        wordLabelTextColor: Color.white.opacity(0.96),
        shortBadgeTopColor: Color(red: 0.31, green: 0.87, blue: 0.76).opacity(0.78),
        shortBadgeBottomColor: Color(red: 0.16, green: 0.74, blue: 0.64).opacity(0.7),
        shortBadgeTextColor: Color(red: 0.04, green: 0.28, blue: 0.33),
        longBadgeTopColor: Color.white.opacity(0.14),
        longBadgeBottomColor: Color.white.opacity(0.05),
        longBadgeTextColor: .white
    )

    static func make(from remote: RemoteAdventureRoadThemeModel?) -> AdventureRoadThemeModel {
        guard let remote else { return .default }
        return AdventureRoadThemeModel(
            backgroundTopColor: color(remote.backgroundTopColor, fallback: Self.default.backgroundTopColor),
            backgroundBottomColor: color(remote.backgroundBottomColor, fallback: Self.default.backgroundBottomColor),
            titleTextColor: color(remote.titleTextColor, fallback: Self.default.titleTextColor),
            subtitleTextColor: color(remote.subtitleTextColor, fallback: Self.default.subtitleTextColor),
            countdownTextColor: color(remote.countdownTextColor, fallback: Self.default.countdownTextColor),
            countdownBackgroundColor: color(remote.countdownBackgroundColor, fallback: Self.default.countdownBackgroundColor),
            wordLabelTextColor: color(remote.wordLabelTextColor, fallback: Self.default.wordLabelTextColor),
            shortBadgeTopColor: color(remote.shortBadgeTopColor, fallback: Self.default.shortBadgeTopColor),
            shortBadgeBottomColor: color(remote.shortBadgeBottomColor, fallback: Self.default.shortBadgeBottomColor),
            shortBadgeTextColor: color(remote.shortBadgeTextColor, fallback: Self.default.shortBadgeTextColor),
            longBadgeTopColor: color(remote.longBadgeTopColor, fallback: Self.default.longBadgeTopColor),
            longBadgeBottomColor: color(remote.longBadgeBottomColor, fallback: Self.default.longBadgeBottomColor),
            longBadgeTextColor: color(remote.longBadgeTextColor, fallback: Self.default.longBadgeTextColor)
        )
    }

    private static func color(_ hex: String?, fallback: Color) -> Color {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else { return fallback }
        return Color(hex: hex)
    }
}

struct AdventureRoadScreenModel {
    let title: String
    let subtitle: String
    let theme: AdventureRoadThemeModel
    let eventEndDate: Date
    let referenceDate: Date
    let shortTermCorrectWords: Int
    let longTermCorrectWords: Int
    let maxWordCount: Int
    let rows: [AdventureRoadRowModel]

    var countdownText: String {
        let components = Calendar.current.dateComponents([.day, .hour], from: referenceDate, to: eventEndDate)
        let day = max(0, components.day ?? 0)
        let hour = max(0, components.hour ?? 0)

        if day == 0, hour == 0 {
            return String(
                localized: "adventure_road_countdown_ended",
                defaultValue: "Time is up",
                comment: "Adventure Road countdown text when the event has ended"
            )
        }

        return String(
            format: String(
                localized: "adventure_road_countdown_format",
                defaultValue: "%d d %d h",
                comment: "Adventure Road countdown format with day and hour placeholders"
            ),
            day,
            hour
        )
    }

    var shortTermProgress: Double {
        normalizedProgress(correctWords: shortTermCorrectWords)
    }

    var longTermProgress: Double {
        normalizedProgress(correctWords: longTermCorrectWords)
    }

    private func normalizedProgress(correctWords: Int) -> Double {
        guard maxWordCount > 0 else { return 0 }
        return min(max(Double(correctWords) / Double(maxWordCount), 0), 1)
    }
}

struct AdventureRoadProgressModel {
    let seasonID: String?
    let monthlyShortLearnedCount: Int
    let monthlyLongLearnedCount: Int
}

enum AdventureMemoryTrack: String, CaseIterable {
    case shortTerm
    case longTerm

    var title: String {
        switch self {
        case .shortTerm:
            return String(
                localized: "adventure_track_short_term",
                defaultValue: "Short Memory",
                comment: "Adventure Road short-term track title"
            )
        case .longTerm:
            return String(
                localized: "adventure_track_long_term",
                defaultValue: "Long Memory",
                comment: "Adventure Road long-term track title"
            )
        }
    }

    var tintColor: Color {
        switch self {
        case .shortTerm:
            return Color(red: 0.18, green: 0.53, blue: 0.83)
        case .longTerm:
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        }
    }
}

struct AdventureMilestoneModel: Identifiable {
    let track: AdventureMemoryTrack
    let wordCount: Int
    let reward: LocalRewardModel
    let status: BountyStatus

    var id: String {
        "\(track.rawValue)-\(wordCount)"
    }
}

struct AdventureRoadRowModel: Identifiable {
    let wordCount: Int
    let leftMilestone: AdventureMilestoneModel
    let rightMilestone: AdventureMilestoneModel

    var id: Int {
        wordCount
    }
}

// MARK: - CLAIMED TIER CODER

/// Encodes / decodes the claimed milestone word counts stored as a comma separated string in Core Data
enum AdventureTierCoder {

    static func decode(_ value: String?) -> Set<Int> {
        guard let value, !value.isEmpty else { return [] }
        return Set(value.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }

    static func encode(_ tiers: Set<Int>) -> String {
        tiers.sorted().map(String.init).joined(separator: ",")
    }

    static func append(_ wordCount: Int, to value: String?) -> String {
        var tiers = decode(value)
        tiers.insert(wordCount)
        return encode(tiers)
    }
}
