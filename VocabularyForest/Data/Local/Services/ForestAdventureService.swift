//
//  ForestAdventureService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.04.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData
import DependencyContainer

// MARK: - ADVENTURE ERROR

enum ForestAdventureError: LocalizedError {
    case networkError
    case unauthenticated
    case emptyForestData
    case emptyForestActivities
    case emptyValueFromConfig
    var errorDescription: String? {
        switch self {
        case .networkError:
            return String(localized: "Network error occurred. Please check your connection.")
        case .unauthenticated:
            return String(localized: "You must be authenticated to use the reward system.")
        case .emptyForestData:
            return String(localized: "Local forest data is not available.")
        case .emptyValueFromConfig:
            return String(localized: "Unexpected error.")
        case .emptyForestActivities:
            return String(localized: "Unexpected error. Error Code: 1001")
        }
    }
}

// MARK: - PROTOCOL

protocol ForestAdventureServiceProtocol {
    func claimDailySpinReward(model: LocalRewardModel) async throws
    func claimWeeklyReward(models: [LocalRewardModel], weeklyModel: WeeklyDailyCardModel) async throws
    func claimAdventureReward(models: [LocalRewardModel], milestone: AdventureMilestoneModel) async throws
    func claimQuestReward(quest: QuestModel) async throws
    func claimLocalReward(model: LocalRewardModel) async throws
    func purchaseMarketItem(item: MarketItemModel) async throws
    func fetchChestDropInfo(chestId: String) async throws -> [ChestDropInfoModel]
}

// MARK: - CONSTANTS
private extension ForestAdventureService {
    enum DefaultsKeys {
        static let dailySpinRewards = "DailySpinConfigID"
        static let questsConfig = "QuestsConfigID"
        static let weeklyRewards = "WeeklyRewardConfigID"
        static let adventureRoadRewards = "AdventureRoadConfigID"
        static let marketConfig = "MarketConfigID"
        static let gameEconomyConfig = "GameEconomyConfigID"
        static let chestRewardConfig = "ChestRewardConfigID"
    }
}

// MARK: - FOREST ADVENTURE SERVICE

class ForestAdventureService {

    private let forestManager: ForestDataManagerProtocol
    private let playerManager: PlayerDataManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    private let documentRepository: DocumentaryRepositoryProtocol
    private let rewardRepository: RewardRepositoryProtocol
    private let questService: QuestServiceProtocol
    private let dailySpinService: DailySpinServiceProtocol
    private let weeklyRewardService: WeeklyRewardServiceProtocol
    private let adventureRoadService: AdventureRoadServiceProtocol
    private let marketService: MarketServiceProtocol
    private let chestService: ChestRepositoryProtocol
    private let gameManager: GameManagerProtocol
    private let logger: AppLoggerProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let db = Firestore.firestore()
    private var questCacheList: [QuestModel]? = nil
    private var dailySpinCacheList: [DailySpinModel]? = nil
    
    init(
        forestManager: ForestDataManagerProtocol,
        playerManager: PlayerDataManagerProtocol,
        coreData: CoreDataManagerProtocol,
        remoteConfig: RemoteConfigRepositoryProtocol,
        documentRepository: DocumentaryRepositoryProtocol,
        rewardRepository: RewardRepositoryProtocol,
        questService: QuestServiceProtocol,
        dailySpinService: DailySpinServiceProtocol,
        weeklyRewardService: WeeklyRewardServiceProtocol,
        adventureRoadService: AdventureRoadServiceProtocol,
        marketService: MarketServiceProtocol,
        chestService: ChestRepositoryProtocol,
        gameManager: GameManagerProtocol,
        logger: AppLoggerProtocol = AppLogger.shared,
        analyticsService: AnalyticsServiceProtocol = NoopAnalyticsService()
    ) {
        self.forestManager = forestManager
        self.playerManager = playerManager
        self.coreDataManager = coreData
        self.remoteConfigRepository = remoteConfig
        self.documentRepository = documentRepository
        self.rewardRepository = rewardRepository
        self.questService = questService
        self.dailySpinService = dailySpinService
        self.weeklyRewardService = weeklyRewardService
        self.adventureRoadService = adventureRoadService
        self.marketService = marketService
        self.chestService = chestService
        self.gameManager = gameManager
        self.logger = logger
        self.analyticsService = analyticsService
        setupParameters()
    }
}

private extension ForestAdventureService {
    func setupParameters() {
        let adventureRoadID = UserDefaults.standard.string(forKey: DefaultsKeys.adventureRoadRewards)
        let marketID = UserDefaults.standard.string(forKey: DefaultsKeys.marketConfig)
        let dailySpinID = UserDefaults.standard.string(forKey: DefaultsKeys.dailySpinRewards)
        let questsID = UserDefaults.standard.string(forKey: DefaultsKeys.questsConfig)
        let weeklyID = UserDefaults.standard.string(forKey: DefaultsKeys.weeklyRewards)
        let gameEconomyID = UserDefaults.standard.string(forKey: DefaultsKeys.gameEconomyConfig)
        let chestRewardID = UserDefaults.standard.string(forKey: DefaultsKeys.chestRewardConfig)
        
        Task {
            do {
            let parameters = await remoteConfigRepository.fetchConfigParameters().data
                
            if chestRewardID == parameters?.model.chestRewardsConfigVersion {
                if let chests = try await documentRepository.fetchChestConfig().chests {
                    try await chestService.processAndSaveChests(from: chests)
                }
            } else if let chestRewardVersion = parameters?.model.chestRewardsConfigVersion {
                UserDefaults.standard.set(chestRewardVersion, forKey: DefaultsKeys.chestRewardConfig)
                let config = try await remoteConfigRepository.fetchChestConfig()
                if let chests = config.model.chests {
                    try await chestService.processAndSaveChests(from: chests)
                    try await documentRepository.saveChestConfig(data: config.rawData)
                }
            }
            if adventureRoadID == parameters?.model.adventureRoadConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchAdventureRoadConfig()
                try await adventureRoadService.convertRemoteToAdventureList(list: response)
            } else if let adventureVersion = parameters?.model.adventureRoadConfigVersion {
                UserDefaults.standard.set(adventureVersion, forKey: DefaultsKeys.adventureRoadRewards)
                let config = try await remoteConfigRepository.fetchAdventureRoadConfig()
                try await adventureRoadService.convertRemoteToAdventureList(list: config.model)
                try await documentRepository.saveAdventureRoadConfig(data: config.rawData)
            }
            if marketID == parameters?.model.marketConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchMarketConfig()
                try await marketService.convertRemoteToMarketList(list: response)
            } else if let marketVersion = parameters?.model.marketConfigVersion {
                UserDefaults.standard.set(marketVersion, forKey: DefaultsKeys.marketConfig)
                let config = try await remoteConfigRepository.fetchMarketConfig()
                try await marketService.convertRemoteToMarketList(list: config.model)
                try await documentRepository.saveMarketConfig(data: config.rawData)
            }
            if dailySpinID == parameters?.model.dailySpinRewardsConfigVersion {
                let response = try await documentRepository.fetchDailySpinModels()
                try await dailySpinService.convertRemoteToDailySpinList(list: response)
            } else if let dailySpinVersion = parameters?.model.dailySpinRewardsConfigVersion {
                UserDefaults.standard.set(dailySpinVersion, forKey: DefaultsKeys.dailySpinRewards)
                let spinRewards = try await remoteConfigRepository.fetchDailySpinRewards()
                try await dailySpinService.convertRemoteToDailySpinList(list: spinRewards.model)
                try await documentRepository.saveDailySpinRewards(data: spinRewards.rawData)
            }
            
            if questsID == parameters?.model.questsConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchQuestsConfig()
                await questService.convertRemoteToCacheQuest(list: response)
                
            }else if let questsVersion = parameters?.model.questsConfigVersion {
                UserDefaults.standard.set(questsVersion, forKey: DefaultsKeys.questsConfig)
                if let remoteResponse = await remoteConfigRepository.fetchQuestsConfig().data {
                    await questService.convertRemoteToCacheQuest(list: remoteResponse.model)
                    try await documentRepository.saveQuestsConfig(data: remoteResponse.rawData)
                }
            }
            if weeklyID == parameters?.model.weeklyRewardsConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchWeeklyRewards()
                try await weeklyRewardService.convertRemoteToWeeklyList(list: response)
            } else if let weeklyVersion = parameters?.model.weeklyRewardsConfigVersion {
                UserDefaults.standard.set(weeklyVersion, forKey: DefaultsKeys.weeklyRewards)
                let weeklyRewards = try await remoteConfigRepository.fetchWeeklyRewards()
                try await weeklyRewardService.convertRemoteToWeeklyList(list: weeklyRewards.model)
                try await documentRepository.saveWeeklyRewards(data: weeklyRewards.rawData)
            }
            if gameEconomyID == parameters?.model.gameEconomyConfigVersion {
                /// Return from local
                let config = try await documentRepository.fetchGameEconomyConfig()
                gameManager.applyEconomyConfig(config)
            } else if let gameEconomyVersion = parameters?.model.gameEconomyConfigVersion {
                UserDefaults.standard.set(gameEconomyVersion, forKey: DefaultsKeys.gameEconomyConfig)
                let config = try await remoteConfigRepository.fetchGameEconomyConfig()
                gameManager.applyEconomyConfig(config.model)
                try await documentRepository.saveGameEconomyConfig(data: config.rawData)
            }
            }
            catch {
                logger.error("Remote config parameter setup failed: \(error.localizedDescription)", category: .sync)
            }
        }
    }
}

// MARK: - QUEST HELPERS

extension ForestAdventureService: ForestAdventureServiceProtocol {
    func claimDailySpinReward(model: LocalRewardModel) async throws {
        /// Lock the spin with network time first so the reward can not be claimed without a saved lock
        try await dailySpinService.claimDailySpinReward()
        try await rewardRepository.claimLocalReward(reward: model)
        analyticsService.log(.dailySpinClaimed(rewardID: rewardID(of: model)))
        logGoldRewards([model], source: AnalyticsGoldSource.dailySpin)
    }

    func claimWeeklyReward(models: [LocalRewardModel], weeklyModel: WeeklyDailyCardModel) async throws {
        /// Lock the streak with network time first so the reward can not be claimed without a saved lock
        try await weeklyRewardService.claimWeeklyReward(model: weeklyModel)
        for model in models {
            try await rewardRepository.claimLocalReward(reward: model)
        }
        analyticsService.log(.weeklyRewardClaimed(dayIndex: weeklyModel.day))
        logGoldRewards(models, source: AnalyticsGoldSource.weeklyReward)
    }

    func claimAdventureReward(models: [LocalRewardModel], milestone: AdventureMilestoneModel) async throws {
        /// Lock the tier with network time first so the reward can not be claimed without a saved lock
        try await adventureRoadService.claimAdventureReward(milestone: milestone)
        for model in models {
            try await rewardRepository.claimLocalReward(reward: model)
        }
        analyticsService.log(.adventureRewardClaimed(milestoneID: milestone.id, seasonID: milestone.track.rawValue))
        logGoldRewards(models, source: AnalyticsGoldSource.adventureRoad)
    }

    func claimLocalReward(model: LocalRewardModel) async throws {
        try await rewardRepository.claimLocalReward(reward: model)
    }

    func purchaseMarketItem(item: MarketItemModel) async throws {
        /// Deduct the currency first so the reward can not be claimed without a paid purchase
        try await marketService.purchaseItem(item: item)
        analyticsService.log(.marketItemPurchased(itemID: item.id, price: item.price.amount))
        analyticsService.log(.virtualCurrencySpent(
            itemName: item.id,
            currencyName: currencyName(of: item.price.currency),
            value: item.price.amount
        ))
    }

    func fetchChestDropInfo(chestId: String) async throws -> [ChestDropInfoModel] {
        analyticsService.log(.chestOpened(chestID: chestId))
        return try await chestService.fetchChestDropInfo(chestId: chestId)
    }

    func claimQuestReward(quest: QuestModel) async throws {
        try await rewardRepository.claimLocalReward(reward: quest.reward)
        try questService.claimQuestReward(quest: quest)
        analyticsService.log(.achievementUnlocked(achievementID: quest.id))
        logGoldRewards([quest.reward], source: AnalyticsGoldSource.quest)
    }
}

// MARK: - ANALYTICS HELPERS

private extension ForestAdventureService {

    func rewardID(of model: LocalRewardModel) -> String {
        switch model.reward {
        case let .standart(reward): return reward.id
        case let .chest(chest): return chest.id
        }
    }

    func currencyName(of currency: MarketCurrency) -> String {
        switch currency {
        case .gold: return AnalyticsVirtualCurrency.gold
        case .diamond: return AnalyticsVirtualCurrency.diamond
        }
    }

    /// The earn/spend pair must be logged completely or the gold-economy reports
    /// become one-sided and useless; every claimed gold reward passes through here.
    func logGoldRewards(_ models: [LocalRewardModel], source: String) {
        for model in models {
            guard case let .standart(reward) = model.reward, reward.category == .gold else { continue }
            analyticsService.log(.virtualCurrencyEarned(
                currencyName: AnalyticsVirtualCurrency.gold,
                value: model.rewardCount,
                source: source
            ))
        }
    }
}

// MARK: - DAILY SPIN REWARDS

extension ForestAdventureService {
    
    func fetchDailySpinStatusDate() async -> Resource<Date?> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .error(error: ForestAdventureError.unauthenticated)
        }
        do {
            let trueNow = try await NetworkTimeHelper.getTrueTime()
            let docRef = db.collection(ForestSyncConstants.usersCollection).document(uid).collection(ForestSyncConstants.dailyRewardsCollection).document(ForestSyncConstants.metadataDocument)
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data(), let lastUsed = (data[ForestSyncConstants.dailySpinLastUsedDateField] as? Timestamp)?.dateValue() {
                let targetTime = lastUsed.addingTimeInterval(86400)
                return .success(targetTime > trueNow ? targetTime : nil)
            }
            return .success(nil)
        } catch {
            let localForestRes = forestManager.fetchSafeForest(contextType: .main)
            if let forest = localForestRes.data, let lastUsed = forest.dailyActivities.dailySpinLastUsedDate {
                let localNow = Date()
                let targetTime = lastUsed.addingTimeInterval(86400)
                return .success(targetTime > localNow ? targetTime : nil)
            }
            return .success(nil)
        }
    }
}

