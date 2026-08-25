//
//  ForestAdventureService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.04.2026.
//

import Foundation
import Combine
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
    /// Emits the first failure of the latest config setup run, nil once a run succeeds.
    var configLoadFailurePublisher: AnyPublisher<ConfigLoadFailure?, Never> { get }
    func retryConfigSetup()
    func claimDailySpinReward(model: LocalRewardModel) async throws
    func claimWeeklyReward(models: [LocalRewardModel], weeklyModel: WeeklyDailyCardModel) async throws
    func claimAdventureReward(models: [LocalRewardModel], milestone: AdventureMilestoneModel) async throws
    func claimQuestReward(quest: QuestModel, rolledRewards: [LocalRewardModel]) async throws
    func claimLocalReward(model: LocalRewardModel) async throws
    func purchaseMarketItem(item: MarketItemModel) async throws
    func fetchChestDropInfo(chestId: String) async throws -> [ChestDropInfoModel]
    func chestPityProgress(chestId: String) -> ChestPityProgressModel?
    func remainingWeeklyPurchases(item: MarketItemModel) -> Int?
    func purchasePackage(_ package: MarketPackageModel) async throws -> [LocalRewardModel]
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
    private let packageService: PackageServiceProtocol
    private let chestService: ChestRepositoryProtocol
    private let gameManager: GameManagerProtocol
    private let logger: AppLoggerProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let db = Firestore.firestore()
    private var questCacheList: [QuestModel]? = nil
    private var dailySpinCacheList: [DailySpinModel]? = nil
    private let configLoadFailureSubject = CurrentValueSubject<ConfigLoadFailure?, Never>(nil)
    private var isConfigSetupRunning = false
    
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
        packageService: PackageServiceProtocol,
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
        self.packageService = packageService
        self.chestService = chestService
        self.gameManager = gameManager
        self.logger = logger
        self.analyticsService = analyticsService
        setupParameters()
    }
}

private extension ForestAdventureService {
    func setupParameters() {
        Task {
            await runConfigSetup()
        }
    }

    func runConfigSetup() async {
        guard !isConfigSetupRunning else { return }
        isConfigSetupRunning = true
        defer { isConfigSetupRunning = false }

        let adventureRoadID = UserDefaults.standard.string(forKey: DefaultsKeys.adventureRoadRewards)
        let marketID = UserDefaults.standard.string(forKey: DefaultsKeys.marketConfig)
        let dailySpinID = UserDefaults.standard.string(forKey: DefaultsKeys.dailySpinRewards)
        let questsID = UserDefaults.standard.string(forKey: DefaultsKeys.questsConfig)
        let weeklyID = UserDefaults.standard.string(forKey: DefaultsKeys.weeklyRewards)
        let gameEconomyID = UserDefaults.standard.string(forKey: DefaultsKeys.gameEconomyConfig)
        let chestRewardID = UserDefaults.standard.string(forKey: DefaultsKeys.chestRewardConfig)

        var runFailure: ConfigLoadFailure? = nil

        func record(_ section: RemoteConfigSection, _ error: Error) {
            let failure = ConfigLoadFailure(section: section, error: error)
            analyticsService.log(.remoteConfigLoadFailed(
                configKey: failure.section.rawValue,
                reason: failure.reason.rawValue,
                detail: failure.detail
            ))
            logger.error("Remote config load failed for \(failure.section.rawValue) [\(failure.reason.rawValue)]: \(failure.detail)", category: .sync)
            /// The popup shows one failure at a time; keep the first so it names the root cause.
            if runFailure == nil {
                runFailure = failure
                configLoadFailureSubject.send(failure)
            }
        }

        func load(_ section: RemoteConfigSection, work: () async throws -> Void) async {
            do {
                try await work()
            } catch {
                record(section, error)
            }
        }

        let parametersResource = await remoteConfigRepository.fetchConfigParameters()
        let parameters = parametersResource.data
        if parameters == nil {
            record(.configParameters, parametersResource.error ?? RemoteConfigError.fetchFailed)
        }

        /// Pity pools reference catalog reward ids, so the catalog must be
        /// registered before any chest can be opened.
        await load(.rewardsCatalog) {
            let catalog = try await remoteConfigRepository.fetchRewardsCatalog()
            chestService.registerRewardCatalog(items: catalog.model.items ?? [])
        }

        /// When the parameter list itself could not be fetched, every section falls
        /// back to the local copy so cached data still opens the screens.
        /// Version ids are persisted only after a section is fully saved; persisting
        /// earlier would make a failed fetch look up to date and block retries.
        await load(.chest) {
            if parameters == nil || chestRewardID == parameters?.model.chestRewardsConfigVersion {
                if let chests = try await documentRepository.fetchChestConfig().chests {
                    try await chestService.processAndSaveChests(from: chests)
                }
            } else if let chestRewardVersion = parameters?.model.chestRewardsConfigVersion {
                let config = try await remoteConfigRepository.fetchChestConfig()
                if let chests = config.model.chests {
                    try await chestService.processAndSaveChests(from: chests)
                    try await documentRepository.saveChestConfig(data: config.rawData)
                    UserDefaults.standard.set(chestRewardVersion, forKey: DefaultsKeys.chestRewardConfig)
                }
            }
        }
        await load(.adventureRoad) {
            if parameters == nil || adventureRoadID == parameters?.model.adventureRoadConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchAdventureRoadConfig()
                try await adventureRoadService.convertRemoteToAdventureList(list: response)
            } else if let adventureVersion = parameters?.model.adventureRoadConfigVersion {
                let config = try await remoteConfigRepository.fetchAdventureRoadConfig()
                try await adventureRoadService.convertRemoteToAdventureList(list: config.model)
                try await documentRepository.saveAdventureRoadConfig(data: config.rawData)
                UserDefaults.standard.set(adventureVersion, forKey: DefaultsKeys.adventureRoadRewards)
            }
        }
        await load(.market) {
            if parameters == nil || marketID == parameters?.model.marketConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchMarketConfig()
                try await marketService.convertRemoteToMarketList(list: response)
                await packageService.convertRemotePackages(list: response)
            } else if let marketVersion = parameters?.model.marketConfigVersion {
                let config = try await remoteConfigRepository.fetchMarketConfig()
                try await marketService.convertRemoteToMarketList(list: config.model)
                await packageService.convertRemotePackages(list: config.model)
                try await documentRepository.saveMarketConfig(data: config.rawData)
                UserDefaults.standard.set(marketVersion, forKey: DefaultsKeys.marketConfig)
            }
        }
        await load(.dailySpin) {
            if parameters == nil || dailySpinID == parameters?.model.dailySpinRewardsConfigVersion {
                let response = try await documentRepository.fetchDailySpinModels()
                try await dailySpinService.convertRemoteToDailySpinList(list: response)
            } else if let dailySpinVersion = parameters?.model.dailySpinRewardsConfigVersion {
                let spinRewards = try await remoteConfigRepository.fetchDailySpinRewards()
                try await dailySpinService.convertRemoteToDailySpinList(list: spinRewards.model)
                try await documentRepository.saveDailySpinRewards(data: spinRewards.rawData)
                UserDefaults.standard.set(dailySpinVersion, forKey: DefaultsKeys.dailySpinRewards)
            }
        }
        await load(.quests) {
            if parameters == nil || questsID == parameters?.model.questsConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchQuestsConfig()
                await questService.convertRemoteToCacheQuest(list: response)
            } else if let questsVersion = parameters?.model.questsConfigVersion {
                let resource = await remoteConfigRepository.fetchQuestsConfig()
                guard let remoteResponse = resource.data else {
                    throw resource.error ?? RemoteConfigError.decodeFailed
                }
                await questService.convertRemoteToCacheQuest(list: remoteResponse.model)
                try await documentRepository.saveQuestsConfig(data: remoteResponse.rawData)
                UserDefaults.standard.set(questsVersion, forKey: DefaultsKeys.questsConfig)
            }
        }
        await load(.weeklyRewards) {
            if parameters == nil || weeklyID == parameters?.model.weeklyRewardsConfigVersion {
                /// Return from local
                let response = try await documentRepository.fetchWeeklyRewards()
                try await weeklyRewardService.convertRemoteToWeeklyList(list: response)
            } else if let weeklyVersion = parameters?.model.weeklyRewardsConfigVersion {
                let weeklyRewards = try await remoteConfigRepository.fetchWeeklyRewards()
                try await weeklyRewardService.convertRemoteToWeeklyList(list: weeklyRewards.model)
                try await documentRepository.saveWeeklyRewards(data: weeklyRewards.rawData)
                UserDefaults.standard.set(weeklyVersion, forKey: DefaultsKeys.weeklyRewards)
            }
        }
        await load(.gameEconomy) {
            if parameters == nil || gameEconomyID == parameters?.model.gameEconomyConfigVersion {
                /// Return from local
                let config = try await documentRepository.fetchGameEconomyConfig()
                gameManager.applyEconomyConfig(config)
            } else if let gameEconomyVersion = parameters?.model.gameEconomyConfigVersion {
                let config = try await remoteConfigRepository.fetchGameEconomyConfig()
                gameManager.applyEconomyConfig(config.model)
                try await documentRepository.saveGameEconomyConfig(data: config.rawData)
                UserDefaults.standard.set(gameEconomyVersion, forKey: DefaultsKeys.gameEconomyConfig)
            }
        }

        if runFailure == nil && configLoadFailureSubject.value != nil {
            configLoadFailureSubject.send(nil)
        }
    }
}

// MARK: - QUEST HELPERS

extension ForestAdventureService: ForestAdventureServiceProtocol {
    var configLoadFailurePublisher: AnyPublisher<ConfigLoadFailure?, Never> {
        configLoadFailureSubject.eraseToAnyPublisher()
    }

    func retryConfigSetup() {
        setupParameters()
    }

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

    func claimQuestReward(quest: QuestModel, rolledRewards: [LocalRewardModel]) async throws {
        /// The claim popup already rolled chest contents; claiming those exact
        /// rewards keeps what the user saw and what the forest receives identical.
        /// The empty fallback covers a failed roll so the reward is never lost.
        let rewards = rolledRewards.isEmpty ? [quest.reward] : rolledRewards
        for model in rewards {
            try await rewardRepository.claimLocalReward(reward: model)
        }
        try questService.claimQuestReward(quest: quest)
        analyticsService.log(.achievementUnlocked(achievementID: quest.id))
        logGoldRewards(rewards, source: AnalyticsGoldSource.quest)
    }

    func purchasePackage(_ package: MarketPackageModel) async throws -> [LocalRewardModel] {
        let granted = try await packageService.purchasePackage(package)
        analyticsService.log(.packagePurchased(productID: package.productId))
        logGoldRewards(granted, source: AnalyticsGoldSource.package)
        return granted
    }

    func chestPityProgress(chestId: String) -> ChestPityProgressModel? {
        chestService.pityProgress(chestId: chestId)
    }

    func remainingWeeklyPurchases(item: MarketItemModel) -> Int? {
        marketService.remainingWeeklyPurchases(item: item)
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

