//
//  ChestRepository.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.05.2026.
//

import Foundation
import DTO

enum ChestRepositoryError: Error {
    case decodingError
    case downloadImageError
    case invalidChestId
    case chestListEmpty
}

protocol ChestRepositoryProtocol {
    func getLocalChest(chestId: String) -> LocalChestModel?
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async throws
    /// Pity pools reference catalog reward ids; register the catalog once so
    /// those ids can be resolved into concrete rewards at open time.
    func registerRewardCatalog(items: [RemoteRewardModel])
    func openChest(chestId: String) async throws -> [LocalRewardModel]
    func fetchChestDropInfo(chestId: String) async throws -> ChestInfoModel
    func pityProgress(chestId: String) -> ChestPityProgressModel?
}

final class ChestRepository {

    private let offlineAssetManager: OfflineAssetManagerProtocol
    private let networkManager: APIServiceProtocol
    private let pityService: ChestPityServiceProtocol
    private let logger: AppLoggerProtocol
    private let analyticsService: AnalyticsServiceProtocol?
    private var localChestModels: [LocalChestModel]?
    private var chestEconomy: [String: RemoteChestEconomy] = [:]
    private var catalogRewardsById: [String: RemoteRewardModel] = [:]
    /// Drop info is static per config version; caching it makes reopening the
    /// info popup instant instead of re-resolving every reward asset.
    private var chestInfoCache: [String: ChestInfoModel] = [:]

    init(
        assetManager: OfflineAssetManagerProtocol,
        apiService: APIServiceProtocol,
        pityService: ChestPityServiceProtocol,
        logger: AppLoggerProtocol = AppLogger.shared,
        analyticsService: AnalyticsServiceProtocol? = nil
    ) {
        self.offlineAssetManager = assetManager
        self.networkManager = apiService
        self.pityService = pityService
        self.logger = logger
        self.analyticsService = analyticsService
    }
    
    // MARK: - Private Downloader
    
    private func downloadAndSaveImageIfNeeded(remotePath: String, localKey: String, version: Int) async throws {
        if offlineAssetManager.isAssetUpToDate(imageName: localKey, expectedVersion: version) {
            return
        }
        
        let getImageModel = GetImageRequestModel(imagePath: remotePath)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            networkManager.fetchImage(values: getImageModel) { [weak self] result in
                guard let self else {
                    continuation.resume(throwing: ChestRepositoryError.downloadImageError)
                    return
                }
                switch result {
                case .success(let imageData):
                    let saveResult = offlineAssetManager.saveImageToAssets(
                        data: imageData,
                        imageName: localKey,
                        version: version
                    )
                    if saveResult.status == .error {
                        continuation.resume(throwing: saveResult.error ?? ChestRepositoryError.downloadImageError)
                    } else {
                        continuation.resume()
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension ChestRepository: ChestRepositoryProtocol {
    func getLocalChest(chestId: String) -> LocalChestModel? {
        guard let localChestModels else { return nil }
        return localChestModels.first { $0.id == chestId }
    }
    
    func openChest(chestId: String) async throws -> [LocalRewardModel] {
        guard let localChestModels else { throw ChestRepositoryError.chestListEmpty }
        guard let chest = localChestModels.first(where: { model in
            model.id == chestId
        }) else { throw ChestRepositoryError.invalidChestId }
        analyticsService?.log(.chestOpened(chestID: chestId))
        let economy = chestEconomy[chest.id]
        var rewards: [LocalRewardModel] = []
        do {
            if let guaranteed = economy?.guaranteedDrops {
                for guarantee in guaranteed {
                    guard let reward = guarantee.reward else { throw ChestRepositoryError.decodingError }
                    let rewardCount = Int.random(in: (guarantee.minAmount ?? 1)...(guarantee.maxAmount ?? 1))
                    let localReward = try await processAndGetLocalReward(from: reward, rewardCount: rewardCount)
                    rewards.append(localReward)
                }
            }
            if let randomDrops = economy?.randomDrops, !randomDrops.isEmpty {
                let totalChance = randomDrops.compactMap { $0.dropChance }.reduce(0, +)
                if totalChance > 0 {
                    /// Roll out of at least 100 so a total below 100 leaves a real chance of no bonus drop
                    let randomRoll = Int.random(in: 1...max(totalChance, 100))
                    var currentWeight = 0
                    for drop in randomDrops {
                        if let chance = drop.dropChance {
                            currentWeight += chance
                            if randomRoll <= currentWeight {
                                guard let reward = drop.reward else { throw ChestRepositoryError.decodingError }
                                let rewardCount = Int.random(in: (drop.minAmount ?? 1)...(drop.maxAmount ?? 1))
                                let localReward = try await processAndGetLocalReward(from: reward, rewardCount: rewardCount)
                                rewards.append(localReward)
                                break
                            }
                        }
                    }
                }
            }
        }catch {
            throw error
        }
        rewards.append(contentsOf: await pityRewards(for: chest))
        if rewards.isEmpty {
            throw ChestRepositoryError.decodingError
        }else {
            return rewards
        }
    }

    func registerRewardCatalog(items: [RemoteRewardModel]) {
        var byId: [String: RemoteRewardModel] = [:]
        for item in items {
            if let id = item.id, byId[id] == nil {
                byId[id] = item
            }
        }
        catalogRewardsById = byId
    }

    func pityProgress(chestId: String) -> ChestPityProgressModel? {
        guard let pity = getLocalChest(chestId: chestId)?.pity else { return nil }
        return pityService.progress(for: pity)
    }
        
    func fetchChestDropInfo(chestId: String) async throws -> ChestInfoModel {
        if let cached = chestInfoCache[chestId] {
            return cached
        }
        guard let economy = chestEconomy[chestId] else { throw ChestRepositoryError.invalidChestId }

        var infoList: [ChestDropInfoModel] = []
        
        if let guaranteed = economy.guaranteedDrops {
            for drop in guaranteed {
                guard let reward = drop.reward, let id = reward.id else { throw ChestRepositoryError.decodingError }
                let localReward = try await processAndGetLocalReward(from: reward, rewardCount: drop.minAmount ?? 1)
                infoList.append(
                    ChestDropInfoModel(
                        id: id,
                        reward: localReward,
                        chancePercent: nil,
                        minAmount: drop.minAmount ?? 1,
                        maxAmount: drop.maxAmount ?? 1
                    )
                )
            }
        }
        
        if let randomDrops = economy.randomDrops {
            for drop in randomDrops {
                guard let reward = drop.reward, let id = reward.id else { throw ChestRepositoryError.decodingError }
                let localReward = try await processAndGetLocalReward(from: reward, rewardCount: drop.minAmount ?? 1)
                infoList.append(
                    ChestDropInfoModel(
                        id: id,
                        reward: localReward,
                        chancePercent: drop.dropChance,
                        minAmount: drop.minAmount ?? 1,
                        maxAmount: drop.maxAmount ?? 1
                    )
                )
            }
        }
        
        guard !infoList.isEmpty else { throw ChestRepositoryError.chestListEmpty }
        let info = ChestInfoModel(
            drops: infoList,
            pityGuarantees: await pityGuaranteeInfo(for: getLocalChest(chestId: chestId))
        )
        chestInfoCache[chestId] = info
        return info
    }
    
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async throws {
        /// A new config version may change drops, so the cached info is stale.
        chestInfoCache = [:]
        var localChests: [LocalChestModel] = []

        for remoteChest in remoteChests {
            if let id = remoteChest.id, let version = remoteChest.version, let chestName = remoteChest.chestName, let version = remoteChest.version, let visuals = remoteChest.visuals, let economy = remoteChest.economy, let closedImagePath = visuals.closedImagePath, let openImagePath = visuals.openImagePath {
                chestEconomy[id] = economy
                let closedChestKey = "\(id)_closed"
                let openChestKey = "\(id)_open"
                
                try await downloadAndSaveImageIfNeeded(remotePath: closedImagePath, localKey: closedChestKey, version: version)
                try await downloadAndSaveImageIfNeeded(remotePath: openImagePath, localKey: openChestKey, version: version)
                
                let localChest = LocalChestModel(
                    id: id,
                    version: version,
                    displayName: chestName,
                    closeLocalImagePath: RewardAssetReference(key: closedChestKey, source: .offlineStorage),
                    openLocalImagePath: RewardAssetReference(key: openChestKey, source: .offlineStorage),
                    textHexColor: remoteChest.textHexColor,
                    backgroundGradientColors: remoteChest.gradientHexBackgroundColors,
                    roadColorHex: remoteChest.roadColorHex,
                    cardGradientHexes: remoteChest.cardGradientHexes,
                    cardTextColorHex: remoteChest.cardTextColorHex,
                    pity: convertPity(remoteChest.pity)
                )
                localChests.append(localChest)
            }else {
                throw ChestRepositoryError.decodingError
            }
        }
        localChestModels = localChests
    }
}

private extension ChestRepository {
    func convertPity(_ remotePity: RemoteChestPity?) -> LocalChestPityModel? {
        guard let remotePity,
              let counterGroup = remotePity.counterGroup,
              let sThreshold = remotePity.sTier?.threshold, sThreshold > 0,
              let sPool = remotePity.sTier?.pool,
              let sPlusThreshold = remotePity.sPlusTier?.threshold, sPlusThreshold > 0,
              let sPlusPool = remotePity.sPlusTier?.pool else {
            return nil
        }
        return LocalChestPityModel(
            counterGroup: counterGroup,
            sTier: LocalChestPityTierModel(threshold: sThreshold, pool: sPool),
            sPlusTier: LocalChestPityTierModel(threshold: sPlusThreshold, pool: sPlusPool),
            naturalDropChanceS: remotePity.naturalDropChanceS ?? 0,
            naturalDropChanceSPlus: remotePity.naturalDropChanceSPlus ?? 0
        )
    }

    /// Bonus S/S+ drops granted by the pity system for a single open. The pity
    /// counter must advance even when a pool reward cannot be resolved, so
    /// resolution failures are logged and skipped instead of failing the open.
    func pityRewards(for chest: LocalChestModel) async -> [LocalRewardModel] {
        guard let pity = chest.pity else { return [] }
        let decision = pityService.registerOpen(pity: pity)
        var rewards: [LocalRewardModel] = []
        for tier in [decision.guaranteedTier, decision.naturalTier].compactMap({ $0 }) {
            /// The rolled pick goes first, but a guarantee must not be lost to a
            /// single unresolvable pool entry, so the rest of the pool backs it up.
            let pool = tier == .sPlus ? pity.sPlusTier.pool : pity.sTier.pool
            var candidates = pool.shuffled()
            if let rolled = pityService.poolRewardId(for: tier, pity: pity) {
                candidates.removeAll { $0 == rolled }
                candidates.insert(rolled, at: 0)
            }
            var granted = false
            for rewardId in candidates {
                guard let remoteReward = catalogRewardsById[rewardId] else {
                    logger.error("Pity pool reward missing from catalog for chest \(chest.id): \(rewardId)", category: .reward)
                    continue
                }
                do {
                    rewards.append(try await processAndGetLocalReward(from: remoteReward, rewardCount: 1))
                    granted = true
                    break
                } catch {
                    logger.error("Pity reward processing failed for \(rewardId): \(error.localizedDescription)", category: .reward)
                }
            }
            if !granted {
                logger.error("Pity guarantee lost: no pool reward resolved for chest \(chest.id), tier \(tier.rawValue)", category: .reward)
            }
        }
        return rewards
    }

    /// Resolves the pity pools into concrete rewards for the info popup. The
    /// popup stays useful even when single pool entries fail to resolve, so
    /// failures are logged and skipped instead of failing the whole fetch.
    private func pityGuaranteeInfo(for chest: LocalChestModel?) async -> [ChestPityInfoModel] {
        guard let chest, let pity = chest.pity else { return [] }
        var guarantees: [ChestPityInfoModel] = []
        let tierConfigs: [(RewardTier, LocalChestPityTierModel)] = [(.s, pity.sTier), (.sPlus, pity.sPlusTier)]
        for (tier, config) in tierConfigs {
            var rewards: [LocalRewardModel] = []
            for rewardId in config.pool {
                guard let remoteReward = catalogRewardsById[rewardId] else {
                    logger.error("Pity pool reward could not be resolved for chest \(chest.id): \(rewardId)", category: .reward)
                    continue
                }
                do {
                    /// Info rows must list the promise even while an asset is not
                    /// yet uploaded; the image view falls back to a placeholder.
                    rewards.append(try await processAndGetLocalReward(from: remoteReward, rewardCount: 1, allowMissingAsset: true))
                } catch {
                    logger.error("Pity pool reward processing failed for \(rewardId): \(error.localizedDescription)", category: .reward)
                }
            }
            if !rewards.isEmpty {
                guarantees.append(ChestPityInfoModel(tier: tier, threshold: config.threshold, rewards: rewards))
            }
        }
        return guarantees
    }

    private func processAndGetLocalReward(from remoteReward: RemoteRewardModel, rewardCount: Int, allowMissingAsset: Bool = false) async throws -> LocalRewardModel {
        var localReward: LocalRewardModel
        
        if let id = remoteReward.id, let type = remoteReward.type, let displayName = remoteReward.displayName, let imageSource = remoteReward.imageSource, let assetName = remoteReward.assetName {
            
            guard let imageSource = ImageSource.convertImageSource(value: imageSource) else { throw RewardRepositoryError.emptySourceError }
            var localRewardType: LocalRewardType
            var posterImage: RewardAssetReference
            let posterName = RewardRepository.posterName(assetName: assetName)
            
            switch imageSource {
            case .local:
                guard let localImageName = remoteReward.localImageName else { throw RewardRepositoryError.emptyLocalImageError }
                posterImage = RewardAssetReference(key: localImageName, source: .appAssets)
            default:
                guard let posterIconPath = remoteReward.posterIconPath,
                      let version = remoteReward.remoteAssetVersion else {
                    throw RewardRepositoryError.emptyRemotePath
                }
                do {
                    try await downloadAndSaveImageIfNeeded(remotePath: posterIconPath, localKey: posterName, version: version)
                } catch where allowMissingAsset {
                    logger.error("Poster download failed for \(posterName), showing placeholder: \(error.localizedDescription)", category: .reward)
                }
                posterImage = RewardAssetReference(key: posterName, source: .offlineStorage)
            }
            
            switch type {
                case "standart":
                    guard let safeCategory = remoteReward.category, let category = QuestRewardModel.convertQuestReward(value: safeCategory) else { throw RewardRepositoryError.emptyCategoryError }
                    localRewardType = LocalRewardType.standart(
                        model: LocalQuestRewardModel(
                            id: id,
                            category: category,
                            tier: remoteReward.rewardTier,
                            displayName: displayName,
                            assetName: assetName,
                            imageSource: imageSource,
                            posterImage: posterImage,
                            remotePath: remoteReward.remotePath,
                            remoteAssetVersion: remoteReward.remoteAssetVersion,
                            textColorHex: remoteReward.textColorHex,
                            textStrokeColorHex: remoteReward.textStrokeColorHex,
                            gradientHexes: remoteReward.gradientHexes,
                            roadColorHex: remoteReward.roadColorHex,
                            cardGradientHexes: remoteReward.cardGradientHexes,
                            cardTextColorHex: remoteReward.cardTextColorHex
                        )
                    )
            default:
                throw RewardRepositoryError.emptyTypeError
            }
            localReward = LocalRewardModel(
                rewardCount: rewardCount,
                reward: localRewardType
            )
            return localReward
        } else {
            throw RewardRepositoryError.decodingError
        }
    }
}
