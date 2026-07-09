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

struct AdventureRoadScreenModel {
    let title: String
    let subtitle: String
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
