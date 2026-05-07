//
//  ChestRewardsConfigStore.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import Foundation
import CoreData

protocol ChestRewardsConfigStoreProtocol: AnyObject {
    func sync(config: ChestRewardsConfigModel)
    func loadLatest() -> ChestRewardsConfigModel?
}

final class ChestRewardsConfigStore: ChestRewardsConfigStoreProtocol {
    private let coreDataManager: CoreDataManagerProtocol

    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }

    func sync(config: ChestRewardsConfigModel) {
        let context = coreDataManager.viewContext

        context.performAndWait {
            upsertConfig(config, in: context)
            syncRewardItems(config.pools, in: context)
            syncVisualItems(config.visuals, in: context)
            coreDataManager.save(in: context)
        }
    }

    func loadLatest() -> ChestRewardsConfigModel? {
        let context = coreDataManager.viewContext

        return context.performAndWait {
            guard let configEntity = fetchConfigEntity(in: context),
                  let safeConfig = try? configEntity.safeObject(context: context) else {
                return nil
            }

            let rewardsRequest: NSFetchRequest<ChestRewardItem> = ChestRewardItem.fetchRequest()
            let rewardEntities = (try? context.fetch(rewardsRequest)) ?? []

            let visualsRequest: NSFetchRequest<ChestVisualItem> = ChestVisualItem.fetchRequest()
            let visualEntities = (try? context.fetch(visualsRequest)) ?? []

            let safeRewards = rewardEntities.compactMap { try? $0.safeObject(context: context) }
            let safeVisuals = visualEntities.compactMap { try? $0.safeObject(context: context) }

            return ChestRewardsConfigModel(
                id: safeConfig.configID,
                season: safeConfig.season,
                odds: ChestRewardOddsModel(
                    goldChestDiamondChance: safeConfig.goldChestDiamondChance,
                    goldChestWaterChance: safeConfig.goldChestWaterChance,
                    natureChestAnimalChance: safeConfig.natureChestAnimalChance,
                    antiqueChestAnimalChance: safeConfig.antiqueChestAnimalChance
                ),
                ranges: ChestRewardRangesModel(
                    goldChestGoldMin: safeConfig.goldChestGoldMin,
                    goldChestGoldMax: safeConfig.goldChestGoldMax,
                    goldChestDiamondMin: safeConfig.goldChestDiamondMin,
                    goldChestDiamondMax: safeConfig.goldChestDiamondMax,
                    goldChestWaterMin: safeConfig.goldChestWaterMin,
                    goldChestWaterMax: safeConfig.goldChestWaterMax,
                    diamondChestDiamondMin: safeConfig.diamondChestDiamondMin,
                    diamondChestDiamondMax: safeConfig.diamondChestDiamondMax
                ),
                pools: ChestRewardPoolsModel(
                    natureAnimals: safeRewards
                        .filter { $0.chestType == "nature" && $0.rewardCategory == "animal" }
                        .map { mapSafeRewardToCandidate($0) },
                    naturePlants: safeRewards
                        .filter { $0.chestType == "nature" && $0.rewardCategory == "plant" }
                        .map { mapSafeRewardToCandidate($0) },
                    antiqueAnimals: safeRewards
                        .filter { $0.chestType == "antique" && $0.rewardCategory == "animal" }
                        .map { mapSafeRewardToCandidate($0) },
                    antiqueSculptures: safeRewards
                        .filter { $0.chestType == "antique" && $0.rewardCategory == "sculpture" }
                        .map { mapSafeRewardToCandidate($0) }
                ),
                visuals: safeVisuals.map { mapSafeVisual($0) }
            )
        }
    }
}

private extension ChestRewardsConfigStore {
    func fetchConfigEntity(in context: NSManagedObjectContext) -> ChestConfig? {
        let request: NSFetchRequest<ChestConfig> = ChestConfig.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(ChestConfig.lastUpdatedDate), ascending: false)]
        return try? context.fetch(request).first
    }

    func upsertConfig(_ config: ChestRewardsConfigModel, in context: NSManagedObjectContext) {
        let request: NSFetchRequest<ChestConfig> = ChestConfig.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(ChestConfig.lastUpdatedDate), ascending: false)]
        let allConfigs = (try? context.fetch(request)) ?? []

        let entity = allConfigs.first ?? ChestConfig(context: context)
        if allConfigs.count > 1 {
            allConfigs.dropFirst().forEach { context.delete($0) }
        }

        entity.id = entity.id ?? UUID()
        entity.configID = config.id?.trimmingCharacters(in: .whitespacesAndNewlines)
        entity.season = config.season?.trimmingCharacters(in: .whitespacesAndNewlines)
        entity.goldChestDiamondChance = Int16(config.odds.goldChestDiamondChance)
        entity.goldChestWaterChance = Int16(config.odds.goldChestWaterChance)
        entity.natureChestAnimalChance = Int16(config.odds.natureChestAnimalChance)
        entity.antiqueChestAnimalChance = Int16(config.odds.antiqueChestAnimalChance)
        entity.goldChestGoldMin = Int16(config.ranges.goldChestGoldMin)
        entity.goldChestGoldMax = Int16(config.ranges.goldChestGoldMax)
        entity.goldChestDiamondMin = Int16(config.ranges.goldChestDiamondMin)
        entity.goldChestDiamondMax = Int16(config.ranges.goldChestDiamondMax)
        entity.goldChestWaterMin = Int16(config.ranges.goldChestWaterMin)
        entity.goldChestWaterMax = Int16(config.ranges.goldChestWaterMax)
        entity.diamondChestDiamondMin = Int16(config.ranges.diamondChestDiamondMin)
        entity.diamondChestDiamondMax = Int16(config.ranges.diamondChestDiamondMax)
        entity.lastUpdatedDate = Date()
    }

    func syncRewardItems(_ pools: ChestRewardPoolsModel, in context: NSManagedObjectContext) {
        let allIncoming: [(chestType: String, item: ChestRewardCandidateModel)] =
            pools.natureAnimals.map { ("nature", $0) } +
            pools.naturePlants.map { ("nature", $0) } +
            pools.antiqueAnimals.map { ("antique", $0) } +
            pools.antiqueSculptures.map { ("antique", $0) }

        let incomingIDs = Set(allIncoming.map { $0.item.id })
        let request: NSFetchRequest<ChestRewardItem> = ChestRewardItem.fetchRequest()
        let localItems = (try? context.fetch(request)) ?? []

        var localByID: [String: ChestRewardItem] = [:]
        for entity in localItems {
            guard let id = entity.id, !id.isEmpty else { continue }
            if localByID[id] == nil {
                localByID[id] = entity
            }
        }

        for local in localItems {
            guard let localID = local.id else {
                context.delete(local)
                continue
            }
            if !incomingIDs.contains(localID) {
                context.delete(local)
            }
        }

        for incoming in allIncoming {
            let item = incoming.item
            let entity = localByID[item.id] ?? ChestRewardItem(context: context)
            entity.id = item.id
            entity.chestType = incoming.chestType
            entity.rewardCategory = item.category
            entity.modelKey = item.modelKey
            entity.probabilityWeight = item.probabilityWeight
            entity.mediaSourceType = item.descriptor.sourceType.rawValue
            entity.mediaFileType = item.descriptor.fileType.rawValue
            entity.previewImageURL = item.descriptor.previewImageURL
            entity.sourceFieldKey = item.descriptor.sourceFieldKey
            entity.sourceVersion = item.descriptor.sourceVersion
            entity.lastUpdatedDate = Date()
        }
    }

    func syncVisualItems(_ visuals: [ChestVisualModel], in context: NSManagedObjectContext) {
        let incomingIDs = Set(visuals.map { $0.id })
        let request: NSFetchRequest<ChestVisualItem> = ChestVisualItem.fetchRequest()
        let localItems = (try? context.fetch(request)) ?? []

        var localByID: [String: ChestVisualItem] = [:]
        for entity in localItems {
            guard let id = entity.id, !id.isEmpty else { continue }
            if localByID[id] == nil {
                localByID[id] = entity
            }
        }

        for local in localItems {
            guard let localID = local.id else {
                context.delete(local)
                continue
            }
            if !incomingIDs.contains(localID) {
                context.delete(local)
            }
        }

        for visual in visuals {
            let entity = localByID[visual.id] ?? ChestVisualItem(context: context)
            entity.id = visual.id
            entity.chestType = visual.chestType
            entity.closedImagePath = visual.closedImagePath
            entity.openImagePath = visual.openImagePath
            entity.lastUpdatedDate = Date()
        }
    }

    func mapSafeRewardToCandidate(_ safe: SafeChestRewardItemModel) -> ChestRewardCandidateModel {
        let sourceType = RewardMediaSourceType(rawValue: safe.mediaSourceType) ?? .remoteBundle
        let fileType = RewardMediaFileType(rawValue: safe.mediaFileType) ?? .image
        return ChestRewardCandidateModel(
            id: safe.id,
            category: safe.rewardCategory,
            modelKey: safe.modelKey,
            probabilityWeight: safe.probabilityWeight > 0 ? safe.probabilityWeight : 1.0,
            descriptor: RewardMediaDescriptor(
                sourceType: sourceType,
                fileType: fileType,
                previewImageURL: safe.previewImageURL,
                sourceFieldKey: safe.sourceFieldKey,
                sourceVersion: safe.sourceVersion
            )
        )
    }

    func mapSafeVisual(_ safe: SafeChestVisualItemModel) -> ChestVisualModel {
        return ChestVisualModel(
            id: safe.id,
            chestType: safe.chestType,
            closedImagePath: safe.closedImagePath,
            openImagePath: safe.openImagePath
        )
    }
}
