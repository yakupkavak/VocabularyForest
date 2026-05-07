//
//  RemoteConfigRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation
import CryptoKit
import FirebaseRemoteConfig

enum RemoteConfigError: Error, LocalizedError {
    case fetchFailed
    case decodeFailed
    case dataMissing
    case internetRequiredForInitialSetup

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return String(localized: "Unable to fetch remote configuration.")
        case .decodeFailed:
            return String(localized: "Unable to decode remote configuration data.")
        case .dataMissing:
            return String(localized: "Remote configuration data is missing.")
        case .internetRequiredForInitialSetup:
            return String(localized: "Internet connection is required to complete the initial setup.")
        }
    }
}

protocol RemoteConfigRepositoryProtocol {
    func fetchDailySpinRewards() async -> Resource<[DailySpinModel]>
    func fetchQuestsConfig() async -> Resource<[QuestModel]>
    func fetchWeeklyRewards() async -> Resource<[WeeklyRewardModel]>
    func fetchStarterCompanionsConfig() async -> Resource<[StarterCompanionModel]>
    func fetchAdventureRoadConfig() async -> Resource<AdventureRoadConfigModel>
    func fetchAdventureRoadRewards() async -> Resource<[AdventureRoadRewardModel]>
    func fetchGameEconomyConfig() async -> Resource<GameEconomyConfigModel>
    func fetchChestRewardsConfig() async -> Resource<ChestRewardsConfigModel>
    func cachedChestRewardsConfig() -> ChestRewardsConfigModel?
}

final class RemoteConfigRepository: RemoteConfigRepositoryProtocol {

    private enum Keys {
        static let dailySpinRewards = "daily_spin_rewards_config"
        static let questsConfig = "quests_config"
        static let weeklyRewards = "weekly_rewards_config"
        static let starterCompanions = "starter_companions_config"
        static let adventureRoadRewards = "adventure_road_rewards_config"
        static let gameEconomyConfig = "game_economy_config"
        static let chestRewardsConfig = "chest_rewards_config"
    }
    
    private enum DefaultsKeys {
        static let remoteConfigIDPrefix = "remote_config.last_id."
    }

    private let remoteConfig: RemoteConfig
    private let userDefaults: UserDefaults
    private let adventureRoadSeasonProgressStore: AdventureRoadSeasonProgressStoreProtocol
    private let chestRewardsConfigStore: ChestRewardsConfigStoreProtocol
    private let chestVisualStorage: ChestVisualStorageProtocol
    private let rewardImageStorage: RewardImageStorageProtocol

    init(
        remoteConfig: RemoteConfig = RemoteConfig.remoteConfig(),
        userDefaults: UserDefaults = .standard,
        adventureRoadSeasonProgressStore: AdventureRoadSeasonProgressStoreProtocol,
        chestRewardsConfigStore: ChestRewardsConfigStoreProtocol,
        chestVisualStorage: ChestVisualStorageProtocol = ChestVisualStorage(),
        rewardImageStorage: RewardImageStorageProtocol = RewardImageStorage()
    ) {
        self.remoteConfig = remoteConfig
        self.userDefaults = userDefaults
        self.adventureRoadSeasonProgressStore = adventureRoadSeasonProgressStore
        self.chestRewardsConfigStore = chestRewardsConfigStore
        self.chestVisualStorage = chestVisualStorage
        self.rewardImageStorage = rewardImageStorage
        let settings = RemoteConfigSettings()
        // For development: 0 fetch interval. Increase for production.
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }

    func fetchDailySpinRewards() async -> Resource<[DailySpinModel]> {
        let decodedResult: Result<DecodedPayload<RemoteDailySpinItemDTO>, RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.dailySpinRewards,
            as: RemoteDailySpinItemDTO.self
        )

        switch decodedResult {
        case .success(let payload):
            _ = persistConfigID(payload.id, forRemoteKey: Keys.dailySpinRewards)
            let safeModels = payload.items.map { dto in
                let mappedReward = mapToRewardPayload(dto.reward)
                return DailySpinModel(
                    weight: safeWeight(dto.weight ?? dto.reward?.safeProbabilityWeight),
                    reward: mappedReward.reward,
                    presentation: mappedReward.presentation
                )
            }
            let imagePaths = Set(safeModels.compactMap { $0.presentation?.imagePath })
            await rewardImageStorage.syncImagePaths(imagePaths)
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)

        case .failure(let error):
            return .error(error: error)
        }
    }
    
    func fetchQuestsConfig() async -> Resource<[QuestModel]> {
        let decodedResult: Result<DecodedPayload<RemoteQuestItemDTO>, RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.questsConfig,
            as: RemoteQuestItemDTO.self
        )
        
        switch decodedResult {
        case .success(let payload):
            _ = persistConfigID(payload.id, forRemoteKey: Keys.questsConfig)
            var seenIDs = Set<UUID>()
            var safeModels: [QuestModel] = []
            
            for dto in payload.items {
                let safeID = safeUUID(from: dto.id)
                if seenIDs.contains(safeID) {
                    continue
                }
                seenIDs.insert(safeID)
                
                let type = QuestType.convertFromCoreData(string: trimmed(dto.type))
                let quest = QuestModel(
                    id: safeID,
                    type: type,
                    title: resolvedLocalizedText(dto.title, fallback: "Quest") ?? "Quest",
                    description: resolvedLocalizedText(dto.descriptionText, fallback: "") ?? "",
                    reward: mapToQuestReward(
                        category: normalized(dto.reward?.category, fallback: "water"),
                        rewardCount: dto.reward?.safeRewardCount ?? 1,
                        imageName: dto.reward?.imageName
                    ),
                    lastUpdatedDate: Date(),
                    status: safeQuestStatus(dto.status),
                    targetCount: safePositive(dto.targetCount, fallback: 1),
                    currentProgressCount: 0,
                    questionType: BattleQuestionType.convertFromCoreData(type: trimmed(dto.questionType)),
                    battleEnemyModel: BattleEnemyModel.convertFromCoreData(string: trimmed(dto.battleEnemyModel)),
                    gameLevel: GameLevel.convertFromCoreData(value: trimmed(dto.gameLevel))
                )

                registerRewardMediaDescriptorIfNeeded(dto.reward)
                safeModels.append(quest)
            }

            let imagePaths = Set(
                payload.items.compactMap { item in
                    let directPath = trimmed(item.reward?.imagePath) ?? trimmed(item.reward?.previewImageURL)
                    if let directPath, !directPath.isEmpty {
                        return directPath
                    }
                    if let imageName = trimmed(item.reward?.imageName), imageName.contains("/") {
                        return imageName
                    }
                    return nil
                }
            )
            await rewardImageStorage.syncImagePaths(imagePaths)
            
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)
            
        case .failure(let error):
            return .error(error: error)
        }
    }

    func fetchStarterCompanionsConfig() async -> Resource<[StarterCompanionModel]> {
        let decodedResult: Result<DecodedPayload<RemoteStarterCompanionItemDTO>, RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.starterCompanions,
            as: RemoteStarterCompanionItemDTO.self
        )

        switch decodedResult {
        case .success(let payload):
            _ = persistConfigID(payload.id, forRemoteKey: Keys.starterCompanions)

            let mapped = payload.items.compactMap { item -> StarterCompanionModel? in
                let modelKey = safeAssetName(from: item.modelKey, fallback: "")
                guard !modelKey.isEmpty else {
                    return nil
                }

                let category = normalized(item.category, fallback: "animal")
                let rawSourceType = normalized(item.mediaSourceType, fallback: RewardMediaSourceType.localAsset.rawValue)
                let sourceType = RewardMediaSourceType(rawValue: rawSourceType) ?? .localAsset
                let fileType = resolveFileType(rawValue: item.mediaFileType, sourceType: sourceType)

                return StarterCompanionModel(
                    id: trimmed(item.id) ?? UUID().uuidString,
                    modelKey: modelKey,
                    category: category,
                    displayName: resolvedLocalizedText(item.displayName, fallback: nil),
                    previewImageName: trimmed(item.previewImageName) ?? modelKey,
                    mediaSourceType: sourceType,
                    mediaFileType: fileType,
                    previewImageURL: nil,
                    sourceFieldKey: trimmed(item.sourceFieldKey),
                    sourceVersion: trimmed(item.sourceVersion)
                )
            }

            let options = mapped.isEmpty ? RewardMediaCatalogStore.localStarterDefaults() : mapped
            let catalogEntries = options.map {
                RewardMediaCatalogEntry(
                    category: $0.category,
                    modelKey: $0.modelKey,
                    descriptor: RewardMediaDescriptor(
                        sourceType: $0.mediaSourceType,
                        fileType: $0.mediaFileType,
                        previewImageURL: $0.previewImageURL,
                        sourceFieldKey: $0.sourceFieldKey,
                        sourceVersion: $0.sourceVersion
                    )
                )
            }
            RewardMediaCatalogStore.save(entries: catalogEntries)
            return .success(options)

        case .failure:
            let localDefaults = RewardMediaCatalogStore.localStarterDefaults()
            let catalogEntries = localDefaults.map {
                RewardMediaCatalogEntry(
                    category: $0.category,
                    modelKey: $0.modelKey,
                    descriptor: RewardMediaDescriptor(
                        sourceType: $0.mediaSourceType,
                        fileType: $0.mediaFileType,
                        previewImageURL: $0.previewImageURL,
                        sourceFieldKey: $0.sourceFieldKey,
                        sourceVersion: $0.sourceVersion
                    )
                )
            }
            RewardMediaCatalogStore.save(entries: catalogEntries)
            return .success(localDefaults)
        }
    }

    func fetchWeeklyRewards() async -> Resource<[WeeklyRewardModel]> {
        let decodedResult: Result<DecodedPayload<RemoteWeeklyRewardItemDTO>, RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.weeklyRewards,
            as: RemoteWeeklyRewardItemDTO.self
        )

        switch decodedResult {
        case .success(let payload):
            _ = persistConfigID(payload.id, forRemoteKey: Keys.weeklyRewards)
            let safeModels = payload.items.enumerated().map { index, dto in
                let mappedReward = mapToRewardPayload(dto.reward)
                return WeeklyRewardModel(
                    id: safeUUID(from: dto.id),
                    day: safeDay(dto.day, fallback: index + 1),
                    reward: mappedReward.reward,
                    presentation: mappedReward.presentation
                )
            }
            let imagePaths = Set(safeModels.compactMap { $0.presentation?.imagePath })
            await rewardImageStorage.syncImagePaths(imagePaths)
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)

        case .failure(let error):
            return .error(error: error)
        }
    }

    func fetchAdventureRoadConfig() async -> Resource<AdventureRoadConfigModel> {
        let decodedResult: Result<DecodedPayload<RemoteAdventureRoadRewardDTO>, RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.adventureRoadRewards,
            as: RemoteAdventureRoadRewardDTO.self
        )

        switch decodedResult {
        case .success(let payload):
            let change = persistConfigID(payload.id, forRemoteKey: Keys.adventureRoadRewards)
            applyAdventureRoadSeasonChangeIfNeeded(change: change, seasonID: payload.id)
            
            guard let seasonEndDate = parseSeasonEndDate(payload.seasonEndDateString) else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            
            let safeModels = payload.items.enumerated().map { index, dto in
                let shortReward = mapToRewardPayload(dto.shortTermReward)
                let longReward = mapToRewardPayload(dto.longTermReward)
                return AdventureRoadRewardModel(
                    wordCount: safeWordCount(dto.wordCount, fallback: (index + 1) * 10),
                    shortTermReward: shortReward.reward,
                    shortTermPresentation: shortReward.presentation,
                    longTermReward: longReward.reward,
                    longTermPresentation: longReward.presentation
                )
            }
            let imagePaths = Set(
                safeModels.compactMap { $0.shortTermPresentation?.imagePath } +
                safeModels.compactMap { $0.longTermPresentation?.imagePath }
            )
            await rewardImageStorage.syncImagePaths(imagePaths)
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(
                AdventureRoadConfigModel(
                    id: payload.id,
                    title: resolvedLocalizedText(payload.title, fallback: "Adventure Road") ?? "Adventure Road",
                    seasonEndDate: seasonEndDate,
                    rewards: safeModels
                )
            )

        case .failure(let error):
            return .error(error: error)
        }
    }
    
    func fetchAdventureRoadRewards() async -> Resource<[AdventureRoadRewardModel]> {
        let configResult = await fetchAdventureRoadConfig()
        switch configResult.status {
        case .success:
            return .success(configResult.data?.rewards ?? [])
        case .loading:
            return .loading()
        case .error:
            return .error(error: configResult.error)
        }
    }
    
    func fetchGameEconomyConfig() async -> Resource<GameEconomyConfigModel> {
        do {
            let jsonString = try await fetchJSONString(forKey: Keys.gameEconomyConfig)
            let data = Data(jsonString.utf8)
            let payload = try JSONDecoder().decode(RemoteGameEconomyPayload.self, from: data)
            _ = persistConfigID(payload.id, forRemoteKey: Keys.gameEconomyConfig)
            
            let minGold = safePositive(payload.killCap?.minGoldPerKill, fallback: EconomyDefaults.minGoldPerKill)
            let maxGoldCandidate = safePositive(payload.killCap?.maxGoldPerKill, fallback: EconomyDefaults.maxGoldPerKill)
            let maxGold = max(minGold, maxGoldCandidate)
            
            let goldChestGoldRange = safeRange(
                min: payload.chestRewardRanges?.goldChestGoldMin,
                max: payload.chestRewardRanges?.goldChestGoldMax,
                fallbackMin: EconomyDefaults.goldChestGoldMin,
                fallbackMax: EconomyDefaults.goldChestGoldMax
            )
            let goldChestDiamondRange = safeRange(
                min: payload.chestRewardRanges?.goldChestDiamondMin,
                max: payload.chestRewardRanges?.goldChestDiamondMax,
                fallbackMin: EconomyDefaults.goldChestDiamondMin,
                fallbackMax: EconomyDefaults.goldChestDiamondMax
            )
            let diamondChestDiamondRange = safeRange(
                min: payload.chestRewardRanges?.diamondChestDiamondMin,
                max: payload.chestRewardRanges?.diamondChestDiamondMax,
                fallbackMin: EconomyDefaults.diamondChestDiamondMin,
                fallbackMax: EconomyDefaults.diamondChestDiamondMax
            )
            let plantPriceMin = safePositive(payload.marketPrices?.plantGoldMin, fallback: EconomyDefaults.plantGoldMin)
            let plantPriceMax = max(
                plantPriceMin,
                safePositive(payload.marketPrices?.plantGoldMax, fallback: EconomyDefaults.plantGoldMax)
            )
            
            let model = GameEconomyConfigModel(
                id: trimmed(payload.id),
                season: trimmed(payload.season) ?? trimmed(payload.seasonID) ?? trimmed(payload.seasonId),
                chestOdds: GameChestOddsModel(
                    goldChestDiamondChance: safePercent(payload.chestOdds?.goldChestDiamondChance, fallback: EconomyDefaults.goldChestDiamondChance),
                    goldChestWaterChance: safePercent(payload.chestOdds?.goldChestWaterChance, fallback: EconomyDefaults.goldChestWaterChance),
                    natureChestAnimalChance: safePercent(payload.chestOdds?.natureChestAnimalChance, fallback: EconomyDefaults.natureChestAnimalChance),
                    antiqueChestAnimalChance: safePercent(payload.chestOdds?.antiqueChestAnimalChance, fallback: EconomyDefaults.antiqueChestAnimalChance)
                ),
                chestRewardRanges: GameChestRewardRangesModel(
                    goldChestGoldMin: goldChestGoldRange.min,
                    goldChestGoldMax: goldChestGoldRange.max,
                    goldChestDiamondMin: goldChestDiamondRange.min,
                    goldChestDiamondMax: goldChestDiamondRange.max,
                    diamondChestDiamondMin: diamondChestDiamondRange.min,
                    diamondChestDiamondMax: diamondChestDiamondRange.max
                ),
                killCap: GameKillCapModel(
                    minGoldPerKill: minGold,
                    maxGoldPerKill: maxGold,
                    dailyKillCountCap: safePositive(payload.killCap?.dailyKillCountCap, fallback: EconomyDefaults.dailyKillCountCap)
                ),
                marketPrices: GameMarketPricesModel(
                    animalGold: safePositive(payload.marketPrices?.animalGold, fallback: EconomyDefaults.animalGold),
                    plantGoldMin: plantPriceMin,
                    plantGoldMax: plantPriceMax,
                    sculptureGold: safePositive(payload.marketPrices?.sculptureGold, fallback: EconomyDefaults.sculptureGold)
                ),
                progressionTargets: GameProgressionTargetsModel(
                    hourlyGoldTarget: safePositive(payload.progressionTargets?.hourlyGoldTarget, fallback: EconomyDefaults.hourlyGoldTarget),
                    adventureRoadTotalGoldTarget: safePositive(
                        payload.progressionTargets?.adventureRoadTotalGoldTarget,
                        fallback: EconomyDefaults.adventureRoadTotalGoldTarget
                    ),
                    rainCost: safePositive(payload.progressionTargets?.rainCost, fallback: EconomyDefaults.rainCost),
                    rainDecayPerHour: safePositive(payload.progressionTargets?.rainDecayPerHour, fallback: EconomyDefaults.rainDecayPerHour),
                    dailyQuestCompletionRateForRain: safeRatio(
                        payload.progressionTargets?.dailyQuestCompletionRateForRain,
                        fallback: EconomyDefaults.dailyQuestCompletionRateForRain
                    )
                )
            )
            
            return .success(model)
        } catch let error as RemoteConfigError {
            return .error(error: error)
        } catch {
            return .error(error: RemoteConfigError.decodeFailed)
        }
    }

    func fetchChestRewardsConfig() async -> Resource<ChestRewardsConfigModel> {
        do {
            let jsonString = try await fetchJSONString(forKey: Keys.chestRewardsConfig)
            let data = Data(jsonString.utf8)
            let payload = try JSONDecoder().decode(RemoteChestRewardsPayload.self, from: data)
            let idChange = persistConfigID(payload.id, forRemoteKey: Keys.chestRewardsConfig)

            if idChange == .unchanged, let cached = chestRewardsConfigStore.loadLatest() {
                await rewardImageStorage.syncImagePaths(rewardPreviewImagePaths(from: cached.pools))
                await chestVisualStorage.syncVisualImages(cached.visuals)
                return .success(cached)
            }

            let odds = ChestRewardOddsModel(
                goldChestDiamondChance: safePercent(payload.odds?.goldChestDiamondChance, fallback: EconomyDefaults.goldChestDiamondChance),
                goldChestWaterChance: safePercent(payload.odds?.goldChestWaterChance, fallback: EconomyDefaults.goldChestWaterChance),
                natureChestAnimalChance: safePercent(payload.odds?.natureChestAnimalChance, fallback: EconomyDefaults.natureChestAnimalChance),
                antiqueChestAnimalChance: safePercent(payload.odds?.antiqueChestAnimalChance, fallback: EconomyDefaults.antiqueChestAnimalChance)
            )

            let goldRange = safeRange(
                min: payload.ranges?.goldChestGoldMin,
                max: payload.ranges?.goldChestGoldMax,
                fallbackMin: EconomyDefaults.goldChestGoldMin,
                fallbackMax: EconomyDefaults.goldChestGoldMax
            )
            let goldDiamondRange = safeRange(
                min: payload.ranges?.goldChestDiamondMin,
                max: payload.ranges?.goldChestDiamondMax,
                fallbackMin: EconomyDefaults.goldChestDiamondMin,
                fallbackMax: EconomyDefaults.goldChestDiamondMax
            )
            let goldWaterRange = safeRange(
                min: payload.ranges?.goldChestWaterMin,
                max: payload.ranges?.goldChestWaterMax,
                fallbackMin: EconomyDefaults.goldChestWaterMin,
                fallbackMax: EconomyDefaults.goldChestWaterMax
            )
            let diamondRange = safeRange(
                min: payload.ranges?.diamondChestDiamondMin,
                max: payload.ranges?.diamondChestDiamondMax,
                fallbackMin: EconomyDefaults.diamondChestDiamondMin,
                fallbackMax: EconomyDefaults.diamondChestDiamondMax
            )

            let pools = ChestRewardPoolsModel(
                natureAnimals: mapChestRewardCandidates(payload.pools?.natureAnimals, fallbackCategory: "animal"),
                naturePlants: mapChestRewardCandidates(payload.pools?.naturePlants, fallbackCategory: "plant"),
                antiqueAnimals: mapChestRewardCandidates(payload.pools?.antiqueAnimals, fallbackCategory: "animal"),
                antiqueSculptures: mapChestRewardCandidates(payload.pools?.antiqueSculptures, fallbackCategory: "sculpture")
            )
            let visuals = mapChestVisuals(payload.visuals)

            let config = ChestRewardsConfigModel(
                id: trimmed(payload.id),
                season: trimmed(payload.season),
                odds: odds,
                ranges: ChestRewardRangesModel(
                    goldChestGoldMin: goldRange.min,
                    goldChestGoldMax: goldRange.max,
                    goldChestDiamondMin: goldDiamondRange.min,
                    goldChestDiamondMax: goldDiamondRange.max,
                    goldChestWaterMin: goldWaterRange.min,
                    goldChestWaterMax: goldWaterRange.max,
                    diamondChestDiamondMin: diamondRange.min,
                    diamondChestDiamondMax: diamondRange.max
                ),
                pools: pools,
                visuals: visuals
            )

            chestRewardsConfigStore.sync(config: config)
            await rewardImageStorage.syncImagePaths(rewardPreviewImagePaths(from: pools))
            await chestVisualStorage.syncVisualImages(config.visuals)
            return .success(config)
        } catch {
            let normalizedError = error as? RemoteConfigError ?? RemoteConfigError.fetchFailed
            if let cached = chestRewardsConfigStore.loadLatest() {
                await rewardImageStorage.syncImagePaths(rewardPreviewImagePaths(from: cached.pools))
                await chestVisualStorage.syncVisualImages(cached.visuals)
                return .error(error: normalizedError)
            }
            if let fallback = fallbackChestRewardsConfig() {
                await rewardImageStorage.syncImagePaths(rewardPreviewImagePaths(from: fallback.pools))
                await chestVisualStorage.syncVisualImages(fallback.visuals)
                return .error(error: normalizedError)
            }
            return .error(error: normalizedError)
        }
    }

    func cachedChestRewardsConfig() -> ChestRewardsConfigModel? {
        chestRewardsConfigStore.loadLatest() ?? fallbackChestRewardsConfig()
    }
}

private extension RemoteConfigRepository {
    struct DecodedPayload<Item> {
        let id: String?
        let title: RemoteLocalizedText?
        let seasonEndDateString: String?
        let items: [Item]
    }
    
    struct RemoteDailySpinItemDTO: Decodable {
        let id: String?
        let weight: Double?
        let reward: RemoteRewardModel?
    }
    
    struct RemoteQuestItemDTO: Decodable {
        let id: String?
        let type: String?
        let title: RemoteLocalizedText?
        let descriptionText: RemoteLocalizedText?
        let reward: RemoteRewardModel?
        let targetCount: Int?
        let questionType: String?
        let battleEnemyModel: String?
        let gameLevel: String?
        let status: String?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case type
            case title
            case descriptionText = "description"
            case reward
            case targetCount
            case questionType
            case battleEnemyModel
            case gameLevel
            case status
        }
    }

    struct RemoteWeeklyRewardItemDTO: Decodable {
        let id: String?
        let day: Int?
        let reward: RemoteRewardModel?

        private enum CodingKeys: String, CodingKey {
            case id
            case day
            case reward
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            if let intValue = try? container.decodeIfPresent(Int.self, forKey: .day) {
                day = intValue
            } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .day) {
                day = Int(doubleValue)
            } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .day),
                      let parsed = Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
                day = parsed
            } else {
                day = nil
            }
            reward = try? container.decodeIfPresent(RemoteRewardModel.self, forKey: .reward)
        }
    }

    struct RemoteStarterCompanionItemDTO: Decodable {
        let id: String?
        let modelKey: String?
        let category: String?
        let displayName: RemoteLocalizedText?
        let previewImageName: String?
        let mediaSourceType: String?
        let mediaFileType: String?
        let sourceFieldKey: String?
        let sourceVersion: String?
    }

    struct RemoteAdventureRoadRewardDTO: Decodable {
        let wordCount: Int?
        let shortTermReward: RemoteRewardModel?
        let longTermReward: RemoteRewardModel?
    }
    
    struct RemoteGameEconomyPayload: Decodable {
        let id: String?
        let season: String?
        let seasonID: String?
        let seasonId: String?
        let chestOdds: RemoteChestOddsDTO?
        let chestRewardRanges: RemoteChestRewardRangesDTO?
        let killCap: RemoteKillCapDTO?
        let marketPrices: RemoteMarketPricesDTO?
        let progressionTargets: RemoteProgressionTargetsDTO?
    }
    
    struct RemoteChestOddsDTO: Decodable {
        let goldChestDiamondChance: Int?
        let goldChestWaterChance: Int?
        let natureChestAnimalChance: Int?
        let antiqueChestAnimalChance: Int?
    }
    
    struct RemoteKillCapDTO: Decodable {
        let minGoldPerKill: Int?
        let maxGoldPerKill: Int?
        let dailyKillCountCap: Int?
    }
    
    struct RemoteChestRewardRangesDTO: Decodable {
        let goldChestGoldMin: Int?
        let goldChestGoldMax: Int?
        let goldChestDiamondMin: Int?
        let goldChestDiamondMax: Int?
        let goldChestWaterMin: Int?
        let goldChestWaterMax: Int?
        let diamondChestDiamondMin: Int?
        let diamondChestDiamondMax: Int?
    }

    struct RemoteMarketPricesDTO: Decodable {
        let animalGold: Int?
        let plantGoldMin: Int?
        let plantGoldMax: Int?
        let sculptureGold: Int?
    }

    struct RemoteProgressionTargetsDTO: Decodable {
        let hourlyGoldTarget: Int?
        let adventureRoadTotalGoldTarget: Int?
        let rainCost: Int?
        let rainDecayPerHour: Int?
        let dailyQuestCompletionRateForRain: Double?
    }

    struct RemoteChestRewardsPayload: Decodable {
        let id: String?
        let season: String?
        let odds: RemoteChestOddsDTO?
        let ranges: RemoteChestRewardRangesDTO?
        let pools: RemoteChestRewardPoolsDTO?
        let visuals: [RemoteChestVisualDTO]?
    }

    struct RemoteChestRewardPoolsDTO: Decodable {
        let natureAnimals: [RemoteRewardModel]?
        let naturePlants: [RemoteRewardModel]?
        let antiqueAnimals: [RemoteRewardModel]?
        let antiqueSculptures: [RemoteRewardModel]?
    }

    struct RemoteChestVisualDTO: Decodable {
        let id: String?
        let chestType: String?
        let closedImagePath: String?
        let openImagePath: String?
    }

    struct RemoteArrayPayload<Item: Decodable>: Decodable {
        let id: String?
        let title: RemoteLocalizedText?
        let seasonTitle: RemoteLocalizedText?
        let seasonEndDate: String?
        let seasonEndDateUTC: String?
        let seasonEndDateUtc: String?
        let items: [Item]?
        let data: [Item]?
        let rewards: [Item]?
    }
    
    enum RemoteConfigIDChange {
        case unchanged
        case firstStored
        case updated
    }
    
    enum EconomyDefaults {
        static let goldChestDiamondChance = 10
        static let goldChestWaterChance = 18
        static let natureChestAnimalChance = 30
        static let antiqueChestAnimalChance = 80
        static let goldChestGoldMin = 120
        static let goldChestGoldMax = 280
        static let goldChestDiamondMin = 2
        static let goldChestDiamondMax = 6
        static let goldChestWaterMin = 35
        static let goldChestWaterMax = 60
        static let diamondChestDiamondMin = 14
        static let diamondChestDiamondMax = 28
        static let minGoldPerKill = 35
        static let maxGoldPerKill = 55
        static let dailyKillCountCap = 60
        static let animalGold = 5000
        static let plantGoldMin = 2000
        static let plantGoldMax = 3000
        static let sculptureGold = 10000
        static let hourlyGoldTarget = 2500
        static let adventureRoadTotalGoldTarget = 10000
        static let rainCost = 100
        static let rainDecayPerHour = 4
        static let dailyQuestCompletionRateForRain = 0.8
    }

    func fetchDecodedArray<T: Decodable>(forKey key: String, as _: T.Type) async -> Result<DecodedPayload<T>, RemoteConfigError> {
        do {
            let jsonString = try await fetchJSONString(forKey: key)
            let payload = try decodePayload(T.self, from: jsonString)
            return .success(payload)
        } catch let error as RemoteConfigError {
            return .failure(error)
        } catch {
            return .failure(.decodeFailed)
        }
    }

    func fetchJSONString(forKey key: String) async throws -> String {
        let cachedValue = trimmedConfigValue(forKey: key)
        let hasCachedValue = !cachedValue.isEmpty

        do {
            let status = try await remoteConfig.fetchAndActivate()

            switch status {
            case .successFetchedFromRemote, .successUsingPreFetchedData:
                break
            case .error:
                if !hasCachedValue {
                    throw RemoteConfigError.fetchFailed
                }
            @unknown default:
                if !hasCachedValue {
                    throw RemoteConfigError.fetchFailed
                }
            }
        } catch {
            if !hasCachedValue {
                throw RemoteConfigError.internetRequiredForInitialSetup
            }
        }

        let latestValue = trimmedConfigValue(forKey: key)
        if !latestValue.isEmpty {
            return latestValue
        }

        if hasCachedValue {
            return cachedValue
        }

        throw RemoteConfigError.dataMissing
    }

    func decodePayload<T: Decodable>(_ type: T.Type, from jsonString: String) throws -> DecodedPayload<T> {
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        if let directArray = try? decoder.decode([T].self, from: data) {
            return DecodedPayload(id: nil, title: nil, seasonEndDateString: nil, items: directArray)
        }

        if let payload = try? decoder.decode(RemoteArrayPayload<T>.self, from: data) {
            return DecodedPayload(
                id: payload.id?.trimmingCharacters(in: .whitespacesAndNewlines),
                title: payload.title ?? payload.seasonTitle,
                seasonEndDateString: payload.seasonEndDate ?? payload.seasonEndDateUTC ?? payload.seasonEndDateUtc,
                items: payload.items ?? payload.data ?? payload.rewards ?? []
            )
        }

        throw RemoteConfigError.decodeFailed
    }
    
    func persistConfigID(_ configID: String?, forRemoteKey remoteKey: String) -> RemoteConfigIDChange {
        guard let configID = configID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !configID.isEmpty else {
            return .unchanged
        }
        
        let key = DefaultsKeys.remoteConfigIDPrefix + remoteKey
        let defaults = userDefaults
        
        guard let previousID = defaults.string(forKey: key), !previousID.isEmpty else {
            defaults.set(configID, forKey: key)
            return .firstStored
        }
        
        guard previousID != configID else {
            return .unchanged
        }
        
        defaults.set(configID, forKey: key)
        return .updated
    }
    
    func applyAdventureRoadSeasonChangeIfNeeded(change: RemoteConfigIDChange, seasonID: String?) {
        guard let seasonID = seasonID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !seasonID.isEmpty else {
            return
        }
        
        switch change {
        case .firstStored:
            updateAdventureRoadProgress(seasonID: seasonID, resetProgress: false)
        case .updated:
            updateAdventureRoadProgress(seasonID: seasonID, resetProgress: true)
        case .unchanged:
            break
        }
    }
    
    func updateAdventureRoadProgress(seasonID: String, resetProgress: Bool) {
        adventureRoadSeasonProgressStore.applySeasonUpdate(
            seasonID: seasonID,
            resetProgress: resetProgress
        )
    }
    
    func parseSeasonEndDate(_ value: String?) -> Date? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
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

    func trimmedConfigValue(forKey key: String) -> String {
        remoteConfig
            .configValue(forKey: key)
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func mapToRewardPayload(_ remoteReward: RemoteRewardModel?) -> (reward: LocalRewardModel, presentation: RewardPresentationModel?) {
        let reward = mapToLocalReward(remoteReward)
        guard let remoteReward else {
            return (reward, nil)
        }

        let directPath = trimmed(remoteReward.imagePath) ?? trimmed(remoteReward.previewImageURL)
        let imageNamePath = trimmed(remoteReward.imageName)
        let resolvedImagePath: String?
        if let directPath, !directPath.isEmpty {
            resolvedImagePath = directPath
        } else if let imageNamePath, imageNamePath.contains("/") {
            resolvedImagePath = imageNamePath
        } else {
            resolvedImagePath = nil
        }

        let chestID = trimmed(remoteReward.chestID)
        let displayName = resolvedLocalizedText(remoteReward.displayName, fallback: nil)

        if resolvedImagePath == nil, chestID == nil, displayName == nil {
            return (reward, nil)
        }

        return (
            reward,
            RewardPresentationModel(
                imagePath: resolvedImagePath,
                chestID: chestID,
                displayName: displayName
            )
        )
    }

    func mapToLocalReward(_ remoteReward: RemoteRewardModel?) -> LocalRewardModel {
        guard let remoteReward else {
            return .standart(model: .water(count: 1))
        }

        registerRewardMediaDescriptorIfNeeded(remoteReward)

        let type = normalized(remoteReward.type, fallback: "resource")
        let category = normalized(remoteReward.category, fallback: "water")

        if type == "chest" {
            return .chest(model: mapToChestReward(category: category, chestID: remoteReward.chestID))
        }

        return .standart(model: mapToQuestReward(category: category, rewardCount: remoteReward.safeRewardCount, imageName: remoteReward.imageName))
    }

    func mapToChestReward(category: String, chestID: String?) -> ChestBountyModel {
        if let chestID,
           let resolvedChestType = resolveChestType(forChestID: chestID) {
            return chestModel(for: resolvedChestType)
        }
        return chestModel(for: category)
    }

    func chestModel(for chestType: String) -> ChestBountyModel {
        switch chestType {
        case "gold":
            return .gold
        case "nature":
            return .nature
        case "diamond":
            return .diamond
        case "antique":
            return .antique
        default:
            return .gold
        }
    }

    func resolveChestType(forChestID chestID: String) -> String? {
        let normalizedID = chestID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedID.isEmpty else { return nil }

        if let config = chestRewardsConfigStore.loadLatest(),
           let visual = config.visuals.first(where: {
               $0.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedID
           }) {
            return visual.chestType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let knownTypes = ["gold", "nature", "diamond", "antique"]
        return knownTypes.first(where: { normalizedID.contains($0) })
    }

    func mapToQuestReward(category: String, rewardCount: Int, imageName: String?) -> QuestRewardModel {
        let safeCount = max(rewardCount, 1)

        switch category {
        case "gold":
            return .gold(count: safeCount)
        case "water":
            return .water(count: safeCount)
        case "diamond":
            return .diamond(count: safeCount)
        case "animal":
            return .animal(modelName: safeAssetName(from: imageName, fallback: "Cat"))
        case "plant":
            return .plant(modelName: safeAssetName(from: imageName, fallback: "SunFlower"))
        case "sculpture":
            return .sculpture(modelName: safeAssetName(from: imageName, fallback: "Deer"))
        default:
            return .water(count: 1)
        }
    }

    func rewardPreviewImagePaths(from pools: ChestRewardPoolsModel) -> Set<String> {
        let allCandidates = pools.natureAnimals + pools.naturePlants + pools.antiqueAnimals + pools.antiqueSculptures
        return Set(
            allCandidates.compactMap { candidate in
                candidate.descriptor.previewImageURL?.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
        )
    }

    func mapChestRewardCandidates(
        _ candidates: [RemoteRewardModel]?,
        fallbackCategory: String
    ) -> [ChestRewardCandidateModel] {
        guard let candidates else { return [] }

        return candidates.compactMap { candidate in
            let category = normalized(candidate.category, fallback: fallbackCategory)
            guard ["animal", "plant", "sculpture"].contains(category) else {
                return nil
            }

            let modelKey = safeAssetName(from: candidate.imageName, fallback: "")
            guard !modelKey.isEmpty else {
                return nil
            }

            let rawType = normalized(candidate.mediaSourceType, fallback: RewardMediaSourceType.remoteBundle.rawValue)
            let sourceType = RewardMediaSourceType(rawValue: rawType) ?? .remoteBundle
            let fileType = resolveFileType(rawValue: candidate.mediaFileType, sourceType: sourceType)

            let model = ChestRewardCandidateModel(
                id: trimmed(candidate.id) ?? "\(category)-\(modelKey.lowercased())",
                category: category,
                modelKey: modelKey,
                probabilityWeight: safeWeight(candidate.probabilityWeight),
                descriptor: RewardMediaDescriptor(
                    sourceType: sourceType,
                    fileType: fileType,
                    previewImageURL: trimmed(candidate.previewImageURL),
                    sourceFieldKey: trimmed(candidate.sourceFieldKey),
                    sourceVersion: trimmed(candidate.sourceVersion)
                )
            )

            RewardMediaCatalogStore.save(category: category, modelKey: modelKey, descriptor: model.descriptor)
            return model
        }
    }

    func mapChestVisuals(_ visuals: [RemoteChestVisualDTO]?) -> [ChestVisualModel] {
        let mapped = (visuals ?? []).compactMap { visual -> ChestVisualModel? in
            let chestType = normalized(visual.chestType, fallback: "")
            let closedImagePath = safeAssetName(from: visual.closedImagePath, fallback: "")
            let openImagePath = safeAssetName(from: visual.openImagePath, fallback: "")
            let id = trimmed(visual.id) ?? "chest-\(chestType)"

            guard !chestType.isEmpty, !closedImagePath.isEmpty, !openImagePath.isEmpty else {
                return nil
            }

            return ChestVisualModel(
                id: id,
                chestType: chestType,
                closedImagePath: closedImagePath,
                openImagePath: openImagePath
            )
        }

        return mapped.isEmpty ? fallbackChestVisuals() : mapped
    }

    func fallbackChestRewardsConfig() -> ChestRewardsConfigModel? {
        let fallbackNatureAnimals = AnimalReward.allCases.map {
            ChestRewardCandidateModel(
                id: "nature-animal-\($0.rawValue.lowercased())",
                category: "animal",
                modelKey: $0.rawValue,
                probabilityWeight: 1.0,
                descriptor: RewardMediaDescriptor(
                    sourceType: .localAsset,
                    fileType: .image,
                    previewImageURL: nil,
                    sourceFieldKey: nil,
                    sourceVersion: nil
                )
            )
        }

        let fallbackNaturePlants = PlantReward.allCases.map {
            ChestRewardCandidateModel(
                id: "nature-plant-\($0.rawValue.lowercased())",
                category: "plant",
                modelKey: $0.rawValue,
                probabilityWeight: 1.0,
                descriptor: RewardMediaDescriptor(
                    sourceType: .remoteBundle,
                    fileType: .image,
                    previewImageURL: nil,
                    sourceFieldKey: nil,
                    sourceVersion: nil
                )
            )
        }

        let fallbackAntiqueAnimals = AnimalReward.allCases.map {
            ChestRewardCandidateModel(
                id: "antique-animal-\($0.rawValue.lowercased())",
                category: "animal",
                modelKey: $0.rawValue,
                probabilityWeight: 1.0,
                descriptor: RewardMediaDescriptor(
                    sourceType: .localAsset,
                    fileType: .image,
                    previewImageURL: nil,
                    sourceFieldKey: nil,
                    sourceVersion: nil
                )
            )
        }

        let fallbackAntiqueSculptures = SculptureReward.allCases.map {
            ChestRewardCandidateModel(
                id: "antique-sculpture-\($0.rawValue.lowercased())",
                category: "sculpture",
                modelKey: $0.rawValue,
                probabilityWeight: 1.0,
                descriptor: RewardMediaDescriptor(
                    sourceType: .remoteBundle,
                    fileType: .image,
                    previewImageURL: nil,
                    sourceFieldKey: nil,
                    sourceVersion: nil
                )
            )
        }

        let visuals = fallbackChestVisuals()

        let fallback = ChestRewardsConfigModel(
            id: "chest_rewards_config_local_fallback",
            season: nil,
            odds: ChestRewardOddsModel(
                goldChestDiamondChance: EconomyDefaults.goldChestDiamondChance,
                goldChestWaterChance: EconomyDefaults.goldChestWaterChance,
                natureChestAnimalChance: EconomyDefaults.natureChestAnimalChance,
                antiqueChestAnimalChance: EconomyDefaults.antiqueChestAnimalChance
            ),
            ranges: ChestRewardRangesModel(
                goldChestGoldMin: EconomyDefaults.goldChestGoldMin,
                goldChestGoldMax: EconomyDefaults.goldChestGoldMax,
                goldChestDiamondMin: EconomyDefaults.goldChestDiamondMin,
                goldChestDiamondMax: EconomyDefaults.goldChestDiamondMax,
                goldChestWaterMin: EconomyDefaults.goldChestWaterMin,
                goldChestWaterMax: EconomyDefaults.goldChestWaterMax,
                diamondChestDiamondMin: EconomyDefaults.diamondChestDiamondMin,
                diamondChestDiamondMax: EconomyDefaults.diamondChestDiamondMax
            ),
            pools: ChestRewardPoolsModel(
                natureAnimals: fallbackNatureAnimals,
                naturePlants: fallbackNaturePlants,
                antiqueAnimals: fallbackAntiqueAnimals,
                antiqueSculptures: fallbackAntiqueSculptures
            ),
            visuals: visuals
        )

        fallbackNatureAnimals.forEach { RewardMediaCatalogStore.save(category: $0.category, modelKey: $0.modelKey, descriptor: $0.descriptor) }
        fallbackNaturePlants.forEach { RewardMediaCatalogStore.save(category: $0.category, modelKey: $0.modelKey, descriptor: $0.descriptor) }
        fallbackAntiqueAnimals.forEach { RewardMediaCatalogStore.save(category: $0.category, modelKey: $0.modelKey, descriptor: $0.descriptor) }
        fallbackAntiqueSculptures.forEach { RewardMediaCatalogStore.save(category: $0.category, modelKey: $0.modelKey, descriptor: $0.descriptor) }

        return fallback
    }

    func fallbackChestVisuals() -> [ChestVisualModel] {
        [
            ChestVisualModel(id: "chest-gold", chestType: "gold", closedImagePath: "assets/chests/gold_chest_close.png", openImagePath: "assets/chests/gold_chest_open.png"),
            ChestVisualModel(id: "chest-nature", chestType: "nature", closedImagePath: "assets/chests/nature_chest_close.png", openImagePath: "assets/chests/nature_chest_open.png"),
            ChestVisualModel(id: "chest-diamond", chestType: "diamond", closedImagePath: "assets/chests/diamond_chest_close.png", openImagePath: "assets/chests/diamond_chest_open.png"),
            ChestVisualModel(id: "chest-antique", chestType: "antique", closedImagePath: "assets/chests/antique_chest_close.png", openImagePath: "assets/chests/antique_chest_open.png")
        ]
    }

    func registerRewardMediaDescriptorIfNeeded(_ remoteReward: RemoteRewardModel?) {
        guard let remoteReward else { return }

        let category = normalized(remoteReward.category, fallback: "")
        guard ["animal", "plant", "sculpture"].contains(category) else {
            return
        }

        let modelKey = safeAssetName(from: remoteReward.imageName, fallback: "")
        guard !modelKey.isEmpty else {
            return
        }

        let rawType = normalized(remoteReward.mediaSourceType, fallback: RewardMediaSourceType.remoteBundle.rawValue)
        let sourceType = RewardMediaSourceType(rawValue: rawType) ?? .remoteBundle
        let fileType = resolveFileType(rawValue: remoteReward.mediaFileType, sourceType: sourceType)

        RewardMediaCatalogStore.save(
            category: category,
            modelKey: modelKey,
            descriptor: RewardMediaDescriptor(
                sourceType: sourceType,
                fileType: fileType,
                previewImageURL: trimmed(remoteReward.previewImageURL),
                sourceFieldKey: trimmed(remoteReward.sourceFieldKey),
                sourceVersion: trimmed(remoteReward.sourceVersion)
            )
        )
    }

    func resolveFileType(rawValue: String?, sourceType: RewardMediaSourceType) -> RewardMediaFileType {
        let normalizedValue = normalized(rawValue, fallback: "")
        if let fileType = RewardMediaFileType(rawValue: normalizedValue) {
            return fileType
        }

        switch sourceType {
        case .remoteBundle:
            return .zip
        case .localAsset:
            return .image
        }
    }

    func safeUUID(from value: String?) -> UUID {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return UUID()
        }

        if let uuid = UUID(uuidString: value) {
            return uuid
        }

        let digest = SHA256.hash(data: Data(value.lowercased().utf8))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        let part1 = String(hex.prefix(8))
        let part2 = String(hex.dropFirst(8).prefix(4))
        let part3 = String(hex.dropFirst(12).prefix(4))
        let part4 = String(hex.dropFirst(16).prefix(4))
        let part5 = String(hex.dropFirst(20).prefix(12))
        let uuidString = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"

        return UUID(uuidString: uuidString) ?? UUID()
    }

    func safeWeight(_ value: Double?) -> Double {
        guard let value, value > 0 else { return 1.0 }
        return value
    }

    func safeDay(_ value: Int?, fallback: Int) -> Int {
        guard let value, value > 0 else { return fallback }
        return value
    }

    func safeWordCount(_ value: Int?, fallback: Int) -> Int {
        guard let value, value > 0 else { return fallback }
        return value
    }

    func normalized(_ text: String?, fallback: String) -> String {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return fallback
    }

    func safeAssetName(from value: String?, fallback: String) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return fallback
    }
    
    func safePercent(_ value: Int?, fallback: Int) -> Int {
        let safeValue = value ?? fallback
        return min(max(safeValue, 0), 100)
    }

    func safeRatio(_ value: Double?, fallback: Double) -> Double {
        let safeValue = value ?? fallback
        return min(max(safeValue, 0), 1)
    }
    
    func safePositive(_ value: Int?, fallback: Int) -> Int {
        guard let value, value > 0 else {
            return fallback
        }
        return value
    }
    
    func safeRange(min minValue: Int?, max maxValue: Int?, fallbackMin: Int, fallbackMax: Int) -> (min: Int, max: Int) {
        let safeMin = safePositive(minValue, fallback: fallbackMin)
        let safeMaxCandidate = safePositive(maxValue, fallback: fallbackMax)
        return (safeMin, Swift.max(safeMin, safeMaxCandidate))
    }
    
    func safeQuestStatus(_ value: String?) -> QuestStatus {
        guard let status = trimmed(value)?.lowercased() else {
            return .active
        }
        return switch status {
        case "locked":
            .locked
        case "completed":
            .completed
        case "claimed":
            .claimed
        case "active":
            .active
        default:
            .active
        }
    }
    
    func trimmed(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    func resolvedLocalizedText(_ value: RemoteLocalizedText?, fallback: String?) -> String? {
        if let localized = trimmed(value?.resolved(locale: .current)) {
            return localized
        }
        return trimmed(fallback)
    }
}
