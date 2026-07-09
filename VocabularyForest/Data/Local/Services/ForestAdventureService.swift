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
}

// MARK: - CONSTANTS
private extension ForestAdventureService {
    enum DefaultsKeys {
        static let dailySpinRewards = "DailySpinConfigID"
        static let questsConfig = "QuestsConfigID"
        static let weeklyRewards = "WeeklyRewardConfigID"
        static let adventureRoadRewards = "AdventureRoadConfigID"
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
    private let chestService: ChestRepositoryProtocol
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
        chestService: ChestRepositoryProtocol,
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
        self.chestService = chestService
        setupParameters()
    }
}

private extension ForestAdventureService {
    func setupParameters() {
        let adventureRoadID = UserDefaults.standard.string(forKey: DefaultsKeys.adventureRoadRewards)
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
            /*
            if gameEconomyID == parameters?.model.gameEconomyConfigVersion {
                // TODO: - RETURN FROM LOCAL
            } else if let gameEconomyVersion = parameters?.model.gameEconomyConfigVersion {
                UserDefaults.standard.set(gameEconomyVersion, forKey: DefaultsKeys.gameEconomyConfig)
                // TODO: - FETCH NEW VERSION FROM REMOTE
            }
             */
            }
            catch {
                print("hata geldi")
                print(error)
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
    }
    
    func claimWeeklyReward(models: [LocalRewardModel], weeklyModel: WeeklyDailyCardModel) async throws {
        /// Lock the streak with network time first so the reward can not be claimed without a saved lock
        try await weeklyRewardService.claimWeeklyReward(model: weeklyModel)
        for model in models {
            try await rewardRepository.claimLocalReward(reward: model)
        }
    }
    
    func claimAdventureReward(models: [LocalRewardModel], milestone: AdventureMilestoneModel) async throws {
        /// Lock the tier with network time first so the reward can not be claimed without a saved lock
        try await adventureRoadService.claimAdventureReward(milestone: milestone)
        for model in models {
            try await rewardRepository.claimLocalReward(reward: model)
        }
    }
    
    func claimLocalReward(model: LocalRewardModel) async throws {
        try await rewardRepository.claimLocalReward(reward: model)
    }
    
    func claimQuestReward(quest: QuestModel) async throws {
        try await rewardRepository.claimLocalReward(reward: quest.reward)
        try questService.claimQuestReward(quest: quest)
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

