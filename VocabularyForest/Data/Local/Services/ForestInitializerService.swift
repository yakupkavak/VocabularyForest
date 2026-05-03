//
//  ForestInitializerService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation
import CoreData

enum ForestInitError: Error {
    case playerCreation
    case forestCreation
    case alreadyCreated
}

protocol ForestInitializerServiceProtocol {
    func initializeNewGame() async -> Resource<Bool>
}

class ForestInitializerService: ForestInitializerServiceProtocol {
    private let forestManager: ForestDataManagerProtocol
    private let playerManager: PlayerDataManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol

    init(
        forestManager: ForestDataManagerProtocol,
        playerManager: PlayerDataManagerProtocol,
        coreData: CoreDataManagerProtocol,
        remoteConfigRepository: RemoteConfigRepositoryProtocol
    ) {
        self.forestManager = forestManager
        self.playerManager = playerManager
        self.coreDataManager = coreData
        self.remoteConfigRepository = remoteConfigRepository
    }
    
    func initializeNewGame() async -> Resource<Bool> {
        let remoteQuestTemplates = await loadRemoteQuestTemplates()
        let forestInitalized = UserDefaults.standard.bool(forKey: "forestInitalized")
        
        if !forestInitalized {
            let playerResult = playerManager.createInitialPlayer(contextType: .background)
            guard playerResult.data != nil else {
                return Resource.error(error: ForestInitError.playerCreation)
            }
            let forestResult = forestManager.createForest(
                helper: ForestGameHelper(),
                contextType: .background
            )
            guard let forest = forestResult.data else {
                return Resource.error(error: ForestInitError.playerCreation)
            }
            _ = playerManager.bindForest(contextType: .background, forest: forest)
            if let remoteQuestTemplates, !remoteQuestTemplates.isEmpty {
                syncLocalQuestDefinitions(with: remoteQuestTemplates, contextType: .background)
            }
            coreDataManager.save(type: .background)
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "forestInitalized")
            }
            return Resource.success(true)
        }else {
            if let remoteQuestTemplates, !remoteQuestTemplates.isEmpty {
                syncLocalQuestDefinitions(with: remoteQuestTemplates, contextType: .background)
            }
            return Resource.error(error: ForestInitError.alreadyCreated)
        }
    }
}

private extension ForestInitializerService {
    func loadRemoteQuestTemplates() async -> [QuestModel]? {
        let result = await remoteConfigRepository.fetchQuestsConfig()
        guard result.status == .success, let templates = result.data, !templates.isEmpty else {
            return nil
        }
        ForestGameHelper.updateRemoteQuestTemplates(templates)
        return templates
    }
    
    func syncLocalQuestDefinitions(
        with templates: [QuestModel],
        contextType: ForestDataManager.ContextType
    ) {
        let context = contextType.context
        context.performAndWait {
            guard let forest = forestManager.getCurrentForest(context: context) else { return }
            let existingQuests = (forest.quests?.allObjects as? [Quest]) ?? []
            let existingPairs: [(UUID, Quest)] = existingQuests.compactMap { quest in
                guard let id = quest.id else { return nil }
                return (id, quest)
            }
            let existingByID: [UUID: Quest] = Dictionary(uniqueKeysWithValues: existingPairs)
            let templateByID: [UUID: QuestModel] = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
            let templateIDs = Set(templateByID.keys)
            var migratedLegacyQuestIDs = Set<NSManagedObjectID>()
            var hasChanges = false
            
            for (questID, template) in templateByID {
                if let existingQuest = existingByID[questID] {
                    if applyTemplate(template, to: existingQuest) {
                        hasChanges = true
                    }
                    continue
                }
                if let legacyQuest = existingQuests.first(where: { quest in
                    !migratedLegacyQuestIDs.contains(quest.objectID) && isLegacyQuestMatch(quest, with: template)
                }) {
                    if applyTemplate(template, to: legacyQuest) {
                        hasChanges = true
                    }
                    migratedLegacyQuestIDs.insert(legacyQuest.objectID)
                    continue
                }
                let newQuest = Quest(context: context)
                fillQuest(newQuest, from: template, touchLastUpdatedDate: true)
                forest.addToQuests(newQuest)
                hasChanges = true
            }
            
            for existingQuest in existingQuests {
                guard let questID = existingQuest.id else {
                    context.delete(existingQuest)
                    hasChanges = true
                    continue
                }
                if !templateIDs.contains(questID) {
                    context.delete(existingQuest)
                    hasChanges = true
                }
            }
            
            if hasChanges {
                coreDataManager.save(in: context)
            }
        }
    }
    
    func applyTemplate(_ template: QuestModel, to quest: Quest) -> Bool {
        let previousID = quest.id
        let previousType = quest.type
        let previousTitle = quest.title
        let previousDescription = quest.description_quest
        let previousRewardType = quest.rewardType
        let previousRewardValue = quest.rewardValue
        let previousStatus = quest.status
        let previousTargetCount = quest.targetCount
        let previousProgress = quest.currentProgressCount
        let previousQuestType = quest.questType
        let previousBattleEnemyModel = quest.battleEnemyModel
        let previousGameLevel = quest.gameLevel
        
        let preservedStatus = quest.status
        let preservedProgress = quest.currentProgressCount
        fillQuest(quest, from: template, touchLastUpdatedDate: false)
        
        if let preservedStatus = preservedStatus?.trimmingCharacters(in: .whitespacesAndNewlines), !preservedStatus.isEmpty {
            quest.status = preservedStatus
        }
        quest.currentProgressCount = min(preservedProgress, Int16(template.targetCount))
        
        let hasChanges =
            previousID != quest.id ||
            previousType != quest.type ||
            previousTitle != quest.title ||
            previousDescription != quest.description_quest ||
            previousRewardType != quest.rewardType ||
            previousRewardValue != quest.rewardValue ||
            previousStatus != quest.status ||
            previousTargetCount != quest.targetCount ||
            previousProgress != quest.currentProgressCount ||
            previousQuestType != quest.questType ||
            previousBattleEnemyModel != quest.battleEnemyModel ||
            previousGameLevel != quest.gameLevel
        
        if hasChanges {
            quest.lastUpdatedDate = Date()
        }
        
        return hasChanges
    }
    
    func fillQuest(_ quest: Quest, from model: QuestModel, touchLastUpdatedDate: Bool) {
        quest.id = model.id
        quest.type = model.type.valueForCoreData
        quest.title = model.title
        quest.description_quest = model.description
        quest.rewardType = model.reward.typeName
        quest.rewardValue = model.reward.coreDataValueString
        quest.status = model.status.valueForCoreData
        quest.targetCount = Int16(model.targetCount)
        quest.currentProgressCount = Int16(model.currentProgressCount)
        quest.questType = model.questionType.valueForCoreData
        quest.battleEnemyModel = model.battleEnemyModel.valueForCoreData
        quest.gameLevel = model.gameLevel.valueForCoreData
        if touchLastUpdatedDate {
            quest.lastUpdatedDate = Date()
        }
    }
    
    func isLegacyQuestMatch(_ quest: Quest, with model: QuestModel) -> Bool {
        QuestType.convertFromCoreData(string: quest.type) == model.type &&
        BattleQuestionType.convertFromCoreData(type: quest.questType) == model.questionType &&
        BattleEnemyModel.convertFromCoreData(string: quest.battleEnemyModel) == model.battleEnemyModel &&
        GameLevel.convertFromCoreData(value: quest.gameLevel) == model.gameLevel &&
        Int(quest.targetCount) == model.targetCount
    }
}
