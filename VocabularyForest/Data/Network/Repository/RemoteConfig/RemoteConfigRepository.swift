//
//  RemoteConfigRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import Foundation
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
    func fetchDailySpinRewards() async throws -> RemoteConfigResponse<RemoteDailySpinListModel>
    func fetchQuestsConfig() async -> Resource<RemoteConfigResponse<RemoteQuestListModel>>
    func fetchWeeklyRewards() async -> Resource<RemoteConfigResponse<RemoteWeeklyListModel>>
    func fetchAdventureRoadConfig() async -> Resource<RemoteConfigResponse<RemoteAdventureRoadListModel>>
    func fetchGameEconomyConfig() async -> Resource<RemoteConfigResponse<GameEconomyConfigModel>>
    func fetchConfigParameters() async -> Resource<RemoteConfigResponse<ConfigParametersList>>
}

private extension RemoteConfigRepository {
    enum Keys {
        static let dailySpinRewards = "daily_spin_rewards_config"
        static let questsConfig = "quests_config"
        static let weeklyRewards = "weekly_rewards_config"
        static let adventureRoadRewards = "adventure_road_rewards_config"
        static let gameEconomyConfig = "game_economy_config"
        static let chestRewardConfig = "chest_rewards_config"
        static let configParameters = "config_list"
    }
    
    private enum DefaultsKeys {
        static let remoteConfigIDPrefix = "remote_config.last_id."
    }
}

final class RemoteConfigRepository: RemoteConfigRepositoryProtocol {
    
    private let remoteConfig: RemoteConfig
    private let userDefaults: UserDefaults

    init(
        remoteConfig: RemoteConfig = RemoteConfig.remoteConfig(),
        userDefaults: UserDefaults = .standard,
    ) {
        self.remoteConfig = remoteConfig
        self.userDefaults = userDefaults
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    func fetchConfigParameters() async -> Resource<RemoteConfigResponse<ConfigParametersList>> {
        do {
            let remoteJson = try await fetchJSONString(forKey: Keys.configParameters)
            let data = Data(remoteJson.utf8)
            let listValue = try JSONDecoder().decode(ConfigParametersList.self, from: data)

            let jsonValue = remoteConfig.configValue(forKey: Keys.configParameters).jsonValue
            let response = RemoteConfigResponse(model: listValue, rawData: jsonValue)
            return Resource.success(response)
        }catch {
            return .error(error: RemoteConfigError.decodeFailed)
        }
    }

    func fetchDailySpinRewards() async throws -> RemoteConfigResponse<RemoteDailySpinListModel> {
        do {
            let listValue = try remoteConfig.configValue(forKey: Keys.dailySpinRewards).decoded(asType: RemoteDailySpinListModel.self)
            let jsonValue = remoteConfig.configValue(forKey: Keys.dailySpinRewards).jsonValue
            let response = RemoteConfigResponse(model: listValue, rawData: jsonValue)
            return response
        }catch {
            throw error
        }
    }
    
    func fetchQuestsConfig() async -> Resource<RemoteConfigResponse<RemoteQuestListModel>> {
        do {
            let listValue = try remoteConfig.configValue(forKey: Keys.questsConfig).decoded(asType: RemoteQuestListModel.self)
            let jsonValue = remoteConfig.configValue(forKey: Keys.questsConfig).jsonValue
            let response = RemoteConfigResponse(model: listValue, rawData: jsonValue)
            return Resource.success(response)
        }catch {
            return .error(error: RemoteConfigError.decodeFailed)
        }
        /*
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
                    title: trimmed(dto.title) ?? "Quest",
                    description: trimmed(dto.descriptionText) ?? "",
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
                safeModels.append(quest)
            }
            
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)
            
        case .failure(let error):
            return .error(error: error)
        }
         */
    }

    func fetchWeeklyRewards() async -> Resource<RemoteConfigResponse<RemoteWeeklyListModel>> {
        do {
            let listValue = try remoteConfig.configValue(forKey: Keys.weeklyRewards).decoded(asType: RemoteWeeklyListModel.self)
            let jsonValue = remoteConfig.configValue(forKey: Keys.weeklyRewards).jsonValue
            let response = RemoteConfigResponse(model: listValue, rawData: jsonValue)
            return Resource.success(response)
        }catch {
            return .error(error: RemoteConfigError.decodeFailed)
        }
        /*
        let decodedResult: Result<DecodedPayload<RemoteWeeklyRewardItemDTO>, RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.weeklyRewards,
            as: RemoteWeeklyRewardItemDTO.self
        )

        switch decodedResult {
        case .success(let payload):
            _ = persistConfigID(payload.id, forRemoteKey: Keys.weeklyRewards)
            let safeModels = payload.items.enumerated().map { index, dto in
                WeeklyRewardModel(
                    id: safeUUID(from: dto.id),
                    day: safeDay(dto.day, fallback: index + 1),
                    reward: mapToLocalReward(dto.reward)
                )
            }
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)

        case .failure(let error):
            return .error(error: error)
        }*/
    }

    func fetchAdventureRoadConfig() async -> Resource<RemoteConfigResponse<RemoteAdventureRoadListModel>>{
        do {
            let listValue = try remoteConfig.configValue(forKey: Keys.adventureRoadRewards).decoded(asType: RemoteAdventureRoadListModel.self)
            let jsonValue = remoteConfig.configValue(forKey: Keys.adventureRoadRewards).jsonValue
            let response = RemoteConfigResponse(model: listValue, rawData: jsonValue)
            return Resource.success(response)
        }catch {
            return .error(error: RemoteConfigError.decodeFailed)
        }
        /*
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
                AdventureRoadRewardModel(
                    wordCount: safeWordCount(dto.wordCount, fallback: (index + 1) * 10),
                    shortTermReward: mapToLocalReward(dto.shortTermReward),
                    longTermReward: mapToLocalReward(dto.longTermReward)
                )
            }
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(
                AdventureRoadConfigModel(
                    id: payload.id,
                    seasonEndDate: seasonEndDate,
                    rewards: safeModels
                )
            )

        case .failure(let error):
            return .error(error: error)
        }
         */
    }
    
    /*
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
    */
    
    func fetchGameEconomyConfig() async -> Resource<RemoteConfigResponse<GameEconomyConfigModel>> {
        do {
            let listValue = try remoteConfig.configValue(forKey: Keys.gameEconomyConfig).decoded(asType: GameEconomyConfigModel.self)
            let jsonValue = remoteConfig.configValue(forKey: Keys.gameEconomyConfig).jsonValue
            let response = RemoteConfigResponse(model: listValue, rawData: jsonValue)
            return Resource.success(response)
        }catch {
            return .error(error: RemoteConfigError.decodeFailed)
        }
        /*
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
         )
         )
         
         return .success(model)
         } catch let error as RemoteConfigError {
         return .error(error: error)
         } catch {
         return .error(error: RemoteConfigError.decodeFailed)
         }
         */
    }
}

private extension RemoteConfigRepository {
    struct DecodedPayload<Item: Decodable>: Decodable{
        let id: String?
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
        let title: String?
        let descriptionText: String?
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
        let diamondChestDiamondMin: Int?
        let diamondChestDiamondMax: Int?
    }

    struct RemoteArrayPayload<Item: Decodable>: Decodable {
        let id: String?
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
        static let goldChestWaterChance = 20
        static let natureChestAnimalChance = 20
        static let antiqueChestAnimalChance = 50
        static let goldChestGoldMin = 50
        static let goldChestGoldMax = 100
        static let goldChestDiamondMin = 1
        static let goldChestDiamondMax = 3
        static let diamondChestDiamondMin = 10
        static let diamondChestDiamondMax = 20
        static let minGoldPerKill = 1
        static let maxGoldPerKill = 3
        static let dailyKillCountCap = 40
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
            return DecodedPayload(id: nil, seasonEndDateString: nil, items: directArray)
        }

        if let payload = try? decoder.decode(RemoteArrayPayload<T>.self, from: data) {
            return DecodedPayload(
                id: payload.id?.trimmingCharacters(in: .whitespacesAndNewlines),
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

    /*
    func mapToLocalReward(_ remoteReward: RemoteRewardModel?) -> LocalRewardModel {
        guard let remoteReward else {
            return .standart(model: .water(count: 1))
        }

        let type = normalized(remoteReward.type, fallback: "resource")
        let category = normalized(remoteReward.category, fallback: "water")

        if type == "chest" {
            return .chest(model: mapToChestReward(category: category))
        }

        return .standart(model: mapToQuestReward(category: category, rewardCount: remoteReward.safeRewardCount, imageName: remoteReward.imageName))
    }
    
    func mapToChestReward(category: String) -> ChestBountyModel {
        switch category {
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
     */
    func safeUUID(from value: String?) -> UUID {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              let uuid = UUID(uuidString: value) else {
            return UUID()
        }
        return uuid
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
}
