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
    case emptyQuestTracks
}

protocol QuestServiceProtocol {
    var questListPublisher: AnyPublisher<[QuestModel], Never> { get }
    var questList: [QuestModel] { get }
    func updateQuest(track: QuestTrackModel) -> Resource<Bool>
    func convertRemoteToCacheQuest(list: RemoteQuestListModel) async -> Resource<Bool>
    func correctAnswer(questionType: BattleQuestionType) throws
    func claimQuestReward(quest: QuestModel) throws
    func fetchCurrentQuestTracks() throws -> [QuestTrackModel]
    func winGame(
        gameLevel: GameLevel,
        battleEnemyMode: BattleEnemyModel,
        questionType: BattleQuestionType
    ) throws
}

final class QuestService {
    
    private let forestManager: ForestDataManagerProtocol
    private let rewardRepository: RewardRepositoryProtocol
    @Published private var activeQuests: [QuestModel] = []
    private var activeQuestTracks: [QuestTrackModel] = []

    init(forestManager: ForestDataManagerProtocol, rewardRepository: RewardRepositoryProtocol) {
        self.forestManager = forestManager
        self.rewardRepository = rewardRepository
    }
    
}

extension QuestService: QuestServiceProtocol {
    func fetchCurrentQuestTracks() throws -> [QuestTrackModel] {
        if let tracks = forestManager.fetchQuestTracks(contextType: .background).data {
            return tracks
        }else {
            throw QuestServiceError.emptyQuestTracks
        }
    }
    
    var questList: [QuestModel] {
        activeQuests
    }
    
    var questListPublisher: AnyPublisher<[QuestModel], Never> {
        $activeQuests.eraseToAnyPublisher()
    }
    
    func claimQuestReward(quest: QuestModel) throws {
        if activeQuests.isEmpty {
            throw QuestServiceError.emptyQuestList
        }
        activeQuests = try activeQuests.map { active in
            var updatedQuest = active
            if updatedQuest.id == quest.id {
                updatedQuest.status = .claimed
                updatedQuest.lastUpdatedDate = Date()
                let questTrack = QuestTrackModel(
                    id: updatedQuest.id,
                    lastUpdatedDate: updatedQuest.lastUpdatedDate,
                    status: updatedQuest.status,
                    currentProgressCount: updatedQuest.currentProgressCount
                )
                try forestManager.updateQuest(questTrack: questTrack, contextType: .background)
            }
            return updatedQuest
        }
    }
    
    ///It increases due to specific quests such as Dragons.
    func winGame(
        gameLevel: GameLevel,
        battleEnemyMode: BattleEnemyModel,
        questionType: BattleQuestionType
    ) throws {
        if activeQuests.isEmpty {
            throw QuestServiceError.emptyQuestList
        }
        activeQuests = try activeQuests.map { quest in
            var updatedQuest = quest
            if updatedQuest.questionType == questionType && updatedQuest.battleEnemyModel == battleEnemyMode && updatedQuest.gameLevel == gameLevel {
                
                updatedQuest.currentProgressCount += 1
                updatedQuest.lastUpdatedDate = Date()
                if updatedQuest.currentProgressCount >= updatedQuest.targetCount {
                    updatedQuest.status = .completed
                    //Todo: Download reward
                }
                let questTrack = QuestTrackModel(
                    id: updatedQuest.id,
                    lastUpdatedDate: updatedQuest.lastUpdatedDate,
                    status: updatedQuest.status,
                    currentProgressCount: updatedQuest.currentProgressCount
                )
                try forestManager.updateQuest(questTrack: questTrack, contextType: .background)
            }
            return updatedQuest
        }
    }
    
    ///It only increases daily quest because it's only counts the correct word amount, not how many enemy defeated.
    func correctAnswer(questionType: BattleQuestionType) throws {
        if activeQuests.isEmpty {
            throw QuestServiceError.emptyQuestList
        }
        activeQuests = try activeQuests.map { quest in
            var updatedQuest = quest
            if updatedQuest.questionType == questionType && updatedQuest.type == .daily {
                updatedQuest.currentProgressCount += 1
                updatedQuest.lastUpdatedDate = Date()
                if updatedQuest.currentProgressCount >= updatedQuest.targetCount {
                    updatedQuest.status = .completed
                }
                let questTrack = QuestTrackModel(
                    id: updatedQuest.id,
                    lastUpdatedDate: updatedQuest.lastUpdatedDate,
                    status: updatedQuest.status,
                    currentProgressCount: updatedQuest.currentProgressCount
                )
                try forestManager.updateQuest(questTrack: questTrack, contextType: .background)
            }
            return updatedQuest
        }
    }
    
    func convertRemoteToCacheQuest(list: RemoteQuestListModel) async -> Resource<Bool> {
        var questList: [QuestModel] = []
        for remoteQuest in list.items {
            if let id = remoteQuest.id, let type = remoteQuest.type,
                let title = remoteQuest.title, let descriptionText = remoteQuest.descriptionText,
                let reward = remoteQuest.reward, let targetCount = remoteQuest.targetCount,
                let questionType = remoteQuest.questionType,
                let battleEnemyModel = remoteQuest.battleEnemyModel,
                let gameLevel = remoteQuest.gameLevel {
                var localReward: LocalRewardModel
                do {
                    localReward = try await rewardRepository.processAndGetLocalReward(from: reward)
                } catch {
                    return Resource<Bool>.error(error: RewardRepositoryError.decodingError)
                }
                
                if let questTrack = try? forestManager.fetchQuestTrack(id: id, contextType: .background) {
                    ///Already fetched quest
                    let quest = QuestModel(
                        id: id,
                        type: QuestType.convertFromCoreData(string: type),
                        title: title.localized,
                        description: descriptionText.localized,
                        reward: localReward,
                        lastUpdatedDate: questTrack.lastUpdatedDate,
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
                        lastUpdatedDate: Date(),
                        status: .active,
                        currentProgressCount: 0
                    )
                    let quest = QuestModel(
                        id: track.id,
                        type: QuestType.convertFromCoreData(string: type),
                        title: title.localized,
                        description: descriptionText.localized,
                        reward: localReward,
                        lastUpdatedDate: track.lastUpdatedDate,
                        status: track.status,
                        targetCount: targetCount,
                        currentProgressCount: track.currentProgressCount,
                        questionType: BattleQuestionType.convertFromCoreData(type: questionType),
                        battleEnemyModel: BattleEnemyModel.convertFromCoreData(string: battleEnemyModel),
                        gameLevel: GameLevel.convertFromCoreData(value: gameLevel)
                    )
                    do {
                        try forestManager.importQuest(track: track, contextType: .background)
                        questList.append(quest)
                    }catch {
                        print(error.localizedDescription)
                        return .error(error: error)
                    }
                    continue
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
