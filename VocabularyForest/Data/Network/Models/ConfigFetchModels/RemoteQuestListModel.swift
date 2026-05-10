//
//  RemoteQuestListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

struct RemoteQuestListModel: Decodable {
    let id: String?
    let seasonEndDateString: String?
    let items: [RemoteQuestModel]
}

struct RemoteQuestModel: Decodable {
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
