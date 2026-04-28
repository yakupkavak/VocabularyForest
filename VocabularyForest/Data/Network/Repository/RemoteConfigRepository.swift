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
    func fetchDailySpinRewards() async -> Resource<[DailySpinModel]>
    func fetchWeeklyRewards() async -> Resource<[WeeklyRewardModel]>
    func fetchAdventureRoadRewards() async -> Resource<[AdventureRoadRewardModel]>
}

final class RemoteConfigRepository: RemoteConfigRepositoryProtocol {

    private enum Keys {
        static let dailySpinRewards = "daily_spin_rewards_config"
        static let weeklyRewards = "weekly_rewards_config"
        static let adventureRoadRewards = "adventure_road_rewards_config"
    }

    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        let settings = RemoteConfigSettings()
        // For development: 0 fetch interval. Increase for production.
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }

    func fetchDailySpinRewards() async -> Resource<[DailySpinModel]> {
        let decodedResult: Result<[RemoteDailySpinItemDTO], RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.dailySpinRewards,
            as: RemoteDailySpinItemDTO.self
        )

        switch decodedResult {
        case .success(let dtos):
            let safeModels = dtos.map { dto in
                DailySpinModel(
                    weight: safeWeight(dto.weight ?? dto.reward?.safeProbabilityWeight),
                    reward: mapToLocalReward(dto.reward)
                )
            }
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)

        case .failure(let error):
            return .error(error: error)
        }
    }

    func fetchWeeklyRewards() async -> Resource<[WeeklyRewardModel]> {
        let decodedResult: Result<[RemoteWeeklyRewardItemDTO], RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.weeklyRewards,
            as: RemoteWeeklyRewardItemDTO.self
        )

        switch decodedResult {
        case .success(let dtos):
            let safeModels = dtos.enumerated().map { index, dto in
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
        }
    }

    func fetchAdventureRoadRewards() async -> Resource<[AdventureRoadRewardModel]> {
        let decodedResult: Result<[RemoteAdventureRoadRewardDTO], RemoteConfigError> = await fetchDecodedArray(
            forKey: Keys.adventureRoadRewards,
            as: RemoteAdventureRoadRewardDTO.self
        )

        switch decodedResult {
        case .success(let dtos):
            let safeModels = dtos.enumerated().map { index, dto in
                AdventureRoadRewardModel(
                    wordCount: safeWordCount(dto.wordCount, fallback: (index + 1) * 10),
                    shortTermReward: mapToLocalReward(dto.shortTermReward),
                    longTermReward: mapToLocalReward(dto.longTermReward)
                )
            }
            guard !safeModels.isEmpty else {
                return .error(error: RemoteConfigError.dataMissing)
            }
            return .success(safeModels)

        case .failure(let error):
            return .error(error: error)
        }
    }
}

private extension RemoteConfigRepository {
    struct RemoteDailySpinItemDTO: Decodable {
        let id: String?
        let weight: Double?
        let reward: RemoteRewardModel?
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

    struct RemoteArrayPayload<Item: Decodable>: Decodable {
        let items: [Item]?
        let data: [Item]?
        let rewards: [Item]?
    }

    func fetchDecodedArray<T: Decodable>(forKey key: String, as _: T.Type) async -> Result<[T], RemoteConfigError> {
        do {
            let jsonString = try await fetchJSONString(forKey: key)
            let items = try decodeArray(T.self, from: jsonString)
            return .success(items)
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

    func decodeArray<T: Decodable>(_ type: T.Type, from jsonString: String) throws -> [T] {
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        if let directArray = try? decoder.decode([T].self, from: data) {
            return directArray
        }

        if let payload = try? decoder.decode(RemoteArrayPayload<T>.self, from: data) {
            return payload.items ?? payload.data ?? payload.rewards ?? []
        }

        throw RemoteConfigError.decodeFailed
    }

    func trimmedConfigValue(forKey key: String) -> String {
        remoteConfig
            .configValue(forKey: key)
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
}
