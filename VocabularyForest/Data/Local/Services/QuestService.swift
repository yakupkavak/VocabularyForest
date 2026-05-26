//
//  QuestService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.05.2026.
//

import Combine
import Foundation

enum QuestServiceError: Error {
    case emptyQuestList
}

protocol QuestServiceProtocol {
    var questListPublisher: AnyPublisher<[QuestModel], Never> { get }
    func updateQuest(track: QuestTrackModel) -> Resource<Bool>
    func convertRemoteToCacheQuest(list: RemoteQuestListModel) async -> Resource<Bool>
    func correctAnswer(questionType: BattleQuestionType) -> Resource<Bool>
}

final class QuestService {
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    @Published private var activeQuests: [QuestModel] = []
    
    init(forestManager: ForestDataManagerProtocol, rewardRepository: RewardRepositoryProtocol) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
    }
    
}

extension QuestService: QuestServiceProtocol {
    
    var questListPublisher: AnyPublisher<[QuestModel], Never> {
        $activeQuests.eraseToAnyPublisher()
    }
    
    ///It increases due to specific quests such as Dragons.
    func winGame(
        gameLevel: GameLevel,
        battleEnemyMode: BattleEnemyModel,
        questionType: BattleQuestionType
    ) -> Resource<Bool> {
        if activeQuests.isEmpty {
            return .error(error: QuestServiceError.emptyQuestList)
        }
        activeQuests = activeQuests.map { quest in
            var updatedQuest = quest
            if updatedQuest.questionType == questionType && updatedQuest.battleEnemyModel == battleEnemyMode && updatedQuest.gameLevel == gameLevel {
                
                updatedQuest.currentProgressCount += 1
                updatedQuest.lastUpdatedDate = Date()
                if updatedQuest.currentProgressCount >= updatedQuest.targetCount {
                    updatedQuest.status = .completed
                }
                let questTrack = QuestTrackModel(
                    id: updatedQuest.id,
                    lastUpdateDate: updatedQuest.lastUpdatedDate,
                    status: updatedQuest.status,
                    currentProgressCount: updatedQuest.currentProgressCount
                )
                if forestManager.updateQuest(questTrack: questTrack, contextType: .background).status == .error {
                    print("Update quest error")
                }
            }
            return updatedQuest
        }
        return Resource.success(true)
    }
    
    ///It only increases daily quest because it's only counts the correct word amount, not how many enemy defeated.
    func correctAnswer(questionType: BattleQuestionType) -> Resource<Bool> {
        if activeQuests.isEmpty {
            return .error(error: QuestServiceError.emptyQuestList)
        }
        activeQuests = activeQuests.map { quest in
            var updatedQuest = quest
            if updatedQuest.questionType == questionType && updatedQuest.type == .daily {
                updatedQuest.currentProgressCount += 1
                updatedQuest.lastUpdatedDate = Date()
                if updatedQuest.currentProgressCount >= updatedQuest.targetCount {
                    updatedQuest.status = .completed
                }
                let questTrack = QuestTrackModel(
                    id: updatedQuest.id,
                    lastUpdateDate: updatedQuest.lastUpdatedDate,
                    status: updatedQuest.status,
                    currentProgressCount: updatedQuest.currentProgressCount
                )
                if forestManager.updateQuest(questTrack: questTrack, contextType: .background).status == .error {
                    print("Update quest error")
                }
            }
            return updatedQuest
        }
        return Resource.success(true)
    }
    
    func convertRemoteToCacheQuest(list: RemoteQuestListModel) async -> Resource<Bool> {
        var questList: [QuestModel] = []
        for remoteQuest in list.items {
            if let id = remoteQuest.id, let type = remoteQuest.type,
                let title = remoteQuest.title, let descriptionText = remoteQuest.descriptionText,
                let reward = remoteQuest.reward, let targetCount = remoteQuest.targetCount,
                let questionType = remoteQuest.questionType,
                let battleEnemyModel = remoteQuest.battleEnemyModel,
                let gameLevel = remoteQuest.gameLevel, let status = remoteQuest.status {
                
                guard let localReward = await rewardRepository.processAndGetLocalReward(from: reward).data else {
                    return Resource<Bool>.error(error: RewardRepositoryError.decodingError)
                }
                
                if let questTrack = forestManager.fetchQuestTrack(id: id, contextType: .background).data {
                    ///Already fetched quest
                    let quest = QuestModel(
                        id: id,
                        type: QuestType.convertFromCoreData(string: type),
                        title: title.localized,
                        description: descriptionText.localized,
                        reward: localReward,
                        lastUpdatedDate: questTrack.lastUpdateDate,
                        status: questTrack.status,
                        targetCount: targetCount,
                        currentProgressCount: questTrack.currentProgressCount,
                        questionType: BattleQuestionType.convertFromCoreData(type: questionType),
                        battleEnemyModel: BattleEnemyModel.convertFromCoreData(string: battleEnemyModel),
                        gameLevel: GameLevel.convertFromCoreData(value: gameLevel)
                    )
                    questList.append(quest)
                }else {
                    ///First time to create quest
                    let track = QuestTrackModel(
                        id: id,
                        lastUpdateDate: Date(),
                        status: .active,
                        currentProgressCount: 0
                    )
                    let quest = QuestModel(
                        id: track.id,
                        type: QuestType.convertFromCoreData(string: type),
                        title: title.localized,
                        description: descriptionText.localized,
                        reward: localReward,
                        lastUpdatedDate: track.lastUpdateDate,
                        status: track.status,
                        targetCount: targetCount,
                        currentProgressCount: track.currentProgressCount,
                        questionType: BattleQuestionType.convertFromCoreData(type: questionType),
                        battleEnemyModel: BattleEnemyModel.convertFromCoreData(string: battleEnemyModel),
                        gameLevel: GameLevel.convertFromCoreData(value: gameLevel)
                    )
                    let importResult = forestManager.importQuest(track: track, contextType: .background)
                    if importResult.status == .success {
                        questList.append(quest)
                    }else {
                        return importResult
                    }
                }
            }else {
                return Resource.error(error: ForestAdventureError.emptyValueFromConfig)
            }
        }
        activeQuests = questList
        return Resource.success(true)
    }
    
    func updateQuest(track: QuestTrackModel) -> Resource<Bool> {
        return .success(true)
    }
}
