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
    let presentation: RewardPresentationModel?
    let isClaimed: Bool

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

enum AdventureRoadMockData {
    static func screenModel() -> AdventureRoadScreenModel {
        let maxWordCount = 500
        let shortWords = 340
        let longWords = 270
        let rows = rows(
            maxWordCount: maxWordCount,
            shortTermCorrectWords: shortWords,
            longTermCorrectWords: longWords
        )

        return AdventureRoadScreenModel(
            title: String(
                localized: "adventure_road_title",
                defaultValue: "Adventure Road",
                comment: "Main title of the Adventure Road screen"
            ),
            eventEndDate: Calendar.current.date(byAdding: .hour, value: 203, to: Date()) ?? Date(),
            referenceDate: Date(),
            shortTermCorrectWords: shortWords,
            longTermCorrectWords: longWords,
            maxWordCount: maxWordCount,
            rows: rows
        )
    }

    static func rows(
        maxWordCount: Int = 500,
        shortTermCorrectWords: Int,
        longTermCorrectWords: Int
    ) -> [AdventureRoadRowModel] {
        let values = stride(from: 10, through: maxWordCount, by: 10)

        return values.map { value in
            AdventureRoadRowModel(
                wordCount: value,
                leftMilestone: milestone(
                    for: .shortTerm,
                    wordCount: value,
                    claimedWordCount: shortTermCorrectWords
                ),
                rightMilestone: milestone(
                    for: .longTerm,
                    wordCount: value,
                    claimedWordCount: longTermCorrectWords
                )
            )
        }
    }

    private static func milestone(
        for track: AdventureMemoryTrack,
        wordCount: Int,
        claimedWordCount: Int
    ) -> AdventureMilestoneModel {
        let milestoneStep = max((wordCount / 10) - 1, 0)
        let isChest = wordCount.isMultiple(of: 50)
        let resourceCycle: [QuestRewardModel] = [
            .gold(count: 0),
            .water(count: 0),
            .gold(count: 0),
            .water(count: 0),
            .diamond(count: 0)
        ]
        let chestCycle: [ChestBountyModel] = track == .shortTerm
            ? [.gold, .diamond, .gold]
            : [.nature, .gold, .nature]
        let reward: LocalRewardModel

        if isChest {
            reward = .chest(model: chestCycle[milestoneStep % chestCycle.count])
        } else {
            let resource = resourceCycle[milestoneStep % resourceCycle.count]
            reward = .standart(model: rewardForResource(resource: resource, step: milestoneStep, track: track))
        }

        return AdventureMilestoneModel(
            track: track,
            wordCount: wordCount,
            reward: reward,
            presentation: nil,
            isClaimed: wordCount <= claimedWordCount
        )
    }

    private static func rewardForResource(
        resource: QuestRewardModel,
        step: Int,
        track: AdventureMemoryTrack
    ) -> QuestRewardModel {
        switch resource {
        case .water:
            let values = track == .shortTerm ? [30, 45, 25, 30, 45] : [10, 15, 10, 15, 20]
            return .water(count: values[step % values.count])
        case .gold:
            let values = track == .shortTerm ? [300, 800, 1000, 450, 600] : [300, 300, 500, 250, 300]
            return .gold(count: values[step % values.count])
        case .diamond:
            let values = track == .shortTerm ? [10, 20, 30, 45, 20] : [5, 10, 10, 15, 20]
            return .diamond(count: values[step % values.count])
        default:
            return .gold(count: 0)
        }
    }
}

enum AdventureRoadBuilder {
    static func screenModel(
        rewards: [AdventureRoadRewardModel],
        progress: AdventureRoadProgressModel,
        title: String,
        eventEndDate: Date,
        referenceDate: Date
    ) -> AdventureRoadScreenModel {
        let sortedRewards = rewards.sorted { $0.wordCount < $1.wordCount }
        let maxWordCount = sortedRewards.map(\.wordCount).max() ?? 0
        let rows = sortedRewards.map { reward in
            AdventureRoadRowModel(
                wordCount: reward.wordCount,
                leftMilestone: AdventureMilestoneModel(
                    track: .shortTerm,
                    wordCount: reward.wordCount,
                    reward: reward.shortTermReward,
                    presentation: reward.shortTermPresentation,
                    isClaimed: reward.wordCount <= progress.monthlyShortLearnedCount
                ),
                rightMilestone: AdventureMilestoneModel(
                    track: .longTerm,
                    wordCount: reward.wordCount,
                    reward: reward.longTermReward,
                    presentation: reward.longTermPresentation,
                    isClaimed: reward.wordCount <= progress.monthlyLongLearnedCount
                )
            )
        }
        
        return AdventureRoadScreenModel(
            title: title,
            eventEndDate: eventEndDate,
            referenceDate: referenceDate,
            shortTermCorrectWords: progress.monthlyShortLearnedCount,
            longTermCorrectWords: progress.monthlyLongLearnedCount,
            maxWordCount: maxWordCount,
            rows: rows
        )
    }
}
