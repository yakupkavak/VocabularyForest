//
//  AdventureRoadService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.07.2026.
//

import Combine
import Foundation

enum AdventureRoadServiceError: Error {
    case emptyRewardList
    case missingSeasonEndDate
    case notClaimable
}

protocol AdventureRoadServiceProtocol {
    var adventureScreenModelPublisher: AnyPublisher<AdventureRoadScreenModel?, Never> { get }
    var adventureScreenModel: AdventureRoadScreenModel? { get }
    
    func convertRemoteToAdventureList(list: RemoteAdventureRoadListModel) async throws
    func checkAndUpdateAdventureState() async
    func claimAdventureReward(milestone: AdventureMilestoneModel) async throws
}

final class AdventureRoadService {
    
    // MARK: - PROPERTIES
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    private let seasonProgressStore: AdventureRoadSeasonProgressStoreProtocol
    private var activeConfig: AdventureRoadConfigModel?
    @Published private var screenModel: AdventureRoadScreenModel?
    
    // MARK: - INIT
    
    init(
        forestManager: ForestDataManagerProtocol,
        rewardRepository: RewardRepositoryProtocol,
        seasonProgressStore: AdventureRoadSeasonProgressStoreProtocol
    ) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
        self.seasonProgressStore = seasonProgressStore
    }
    
}

extension AdventureRoadService: AdventureRoadServiceProtocol {
    
    var adventureScreenModelPublisher: AnyPublisher<AdventureRoadScreenModel?, Never> {
        $screenModel.eraseToAnyPublisher()
    }
    
    var adventureScreenModel: AdventureRoadScreenModel? {
        screenModel
    }
    
    func convertRemoteToAdventureList(list: RemoteAdventureRoadListModel) async throws {
        guard let items = list.items, !items.isEmpty else { throw AdventureRoadServiceError.emptyRewardList }
        guard let seasonEndDate = parseSeasonEndDate(list.seasonEndDateString) else {
            throw AdventureRoadServiceError.missingSeasonEndDate
        }
        
        var rewards: [AdventureRoadRewardModel] = []
        
        for item in items {
            guard let wordCount = item.wordCount,
                  let shortRemote = item.shortTermReward,
                  let longRemote = item.longTermReward else { continue }
            /// Don't mask repository errors as decodingError, the real cause (download, chest lookup...) must surface
            let shortReward = try await rewardRepository.processAndGetLocalReward(from: shortRemote)
            let longReward = try await rewardRepository.processAndGetLocalReward(from: longRemote)
            rewards.append(
                AdventureRoadRewardModel(
                    wordCount: wordCount,
                    shortTermReward: shortReward,
                    longTermReward: longReward
                )
            )
        }
        
        guard !rewards.isEmpty else { throw AdventureRoadServiceError.emptyRewardList }
        
        activeConfig = AdventureRoadConfigModel(
            id: list.id,
            title: list.title?.localized,
            description: list.description?.localized,
            theme: AdventureRoadThemeModel.make(from: list.theme),
            seasonEndDate: seasonEndDate,
            rewards: rewards.sorted { $0.wordCount < $1.wordCount }
        )
        applySeasonChangeIfNeeded(configID: list.id)
        await checkAndUpdateAdventureState()
    }
    
    func checkAndUpdateAdventureState() async {
        do {
            let trueNow = try await NetworkTimeHelper.getTrueTime()
            updateAdventureState(now: trueNow)
        } catch {
            /// Offline fallback: keep the countdown with local time instead of failing open
            updateAdventureState(now: Date())
        }
    }
    
    func claimAdventureReward(milestone: AdventureMilestoneModel) async throws {
        let trueNow = try await NetworkTimeHelper.getTrueTime()
        let progress = fetchProgressContext()
        
        let learnedCount: Int
        let claimedTiers: Set<Int>
        switch milestone.track {
        case .shortTerm:
            learnedCount = progress.shortLearnedCount
            claimedTiers = progress.claimedShortTiers
        case .longTerm:
            learnedCount = progress.longLearnedCount
            claimedTiers = progress.claimedLongTiers
        }
        
        guard milestone.wordCount <= learnedCount, !claimedTiers.contains(milestone.wordCount) else {
            throw AdventureRoadServiceError.notClaimable
        }
        
        try forestManager.updateClaimedAdventureTier(
            track: milestone.track,
            wordCount: milestone.wordCount,
            time: trueNow,
            contextType: .main
        )
        updateAdventureState(now: trueNow)
    }
}

private extension AdventureRoadService {
    
    struct AdventureProgressContext {
        let shortLearnedCount: Int
        let longLearnedCount: Int
        let claimedShortTiers: Set<Int>
        let claimedLongTiers: Set<Int>
    }
    
    func fetchProgressContext() -> AdventureProgressContext {
        let localForestRes = forestManager.fetchSafeForest(contextType: .main)
        guard let activities = localForestRes.data?.dailyActivities else {
            return AdventureProgressContext(
                shortLearnedCount: 0,
                longLearnedCount: 0,
                claimedShortTiers: [],
                claimedLongTiers: []
            )
        }
        return AdventureProgressContext(
            shortLearnedCount: activities.monthlyShortLearnedCount,
            longLearnedCount: activities.monthlyLongLearnedCount,
            claimedShortTiers: AdventureTierCoder.decode(activities.claimedShortTiers),
            claimedLongTiers: AdventureTierCoder.decode(activities.claimedLongTiers)
        )
    }
    
    func applySeasonChangeIfNeeded(configID: String?) {
        guard let configID, !configID.isEmpty else { return }
        let storedID = forestManager.fetchSafeForest(contextType: .main).data?.dailyActivities.adventureSeasonID
        guard storedID != configID else { return }
        /// Reset the progress only when switching from an older season, first launch just stores the ID
        seasonProgressStore.applySeasonUpdate(seasonID: configID, resetProgress: storedID != nil)
    }
    
    func updateAdventureState(now: Date) {
        guard let config = activeConfig else { return }
        
        let progress = fetchProgressContext()
        let rows = config.rewards.map { reward in
            AdventureRoadRowModel(
                wordCount: reward.wordCount,
                leftMilestone: AdventureMilestoneModel(
                    track: .shortTerm,
                    wordCount: reward.wordCount,
                    reward: reward.shortTermReward,
                    status: milestoneStatus(
                        wordCount: reward.wordCount,
                        learnedCount: progress.shortLearnedCount,
                        claimedTiers: progress.claimedShortTiers
                    )
                ),
                rightMilestone: AdventureMilestoneModel(
                    track: .longTerm,
                    wordCount: reward.wordCount,
                    reward: reward.longTermReward,
                    status: milestoneStatus(
                        wordCount: reward.wordCount,
                        learnedCount: progress.longLearnedCount,
                        claimedTiers: progress.claimedLongTiers
                    )
                )
            )
        }
        
        let model = AdventureRoadScreenModel(
            title: config.title ?? String(
                localized: "adventure_road_title",
                defaultValue: "Adventure Road",
                comment: "Main title of the Adventure Road screen"
            ),
            subtitle: config.description ?? "",
            theme: config.theme,
            eventEndDate: config.seasonEndDate,
            referenceDate: now,
            shortTermCorrectWords: progress.shortLearnedCount,
            longTermCorrectWords: progress.longLearnedCount,
            maxWordCount: config.rewards.map(\.wordCount).max() ?? 0,
            rows: rows
        )
        
        DispatchQueue.main.async {
            self.screenModel = model
        }
    }
    
    func milestoneStatus(wordCount: Int, learnedCount: Int, claimedTiers: Set<Int>) -> BountyStatus {
        if claimedTiers.contains(wordCount) {
            return .claimed
        }
        if wordCount <= learnedCount {
            return .ready
        }
        return .locked
    }
    
    func parseSeasonEndDate(_ value: String?) -> Date? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: raw) {
            return date
        }
        
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        return fallbackFormatter.date(from: raw)
    }
}
