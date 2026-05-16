//
//  RemoteAdventureRoadListModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.05.2026.
//

import Foundation

struct RemoteAdventureRoadListModel: Decodable {
    let id: String?
    let title: RemoteLocalizedText?
    let seasonEndDate: Date?
    let items: [RemoteAdventureRoadModel]?
}

struct RemoteAdventureRoadModel: Decodable {
    let id: String?
    let wordCount: Int?
    let shortTermReward, longTermReward: RemoteTermReward?
}

struct RemoteTermReward: Decodable {
    let id: String?
    let rewardType: String? // chest or resource
    let rewardCategory: String? // water, gold, antiqueChest
    let rewardCount: Int?
    let localImageName: String?
    let remoteImagePath: String?
    let displayName: RemoteLocalizedText?
    let chestID: String?

    enum CodingKeys: String, CodingKey {
        case id, rewardType, rewardCategory, rewardCount, localImageName, remoteImagePath, displayName
        case chestID = "chestId"
    }
}

extension RemoteTermReward {
    func convertLocalReward() -> LocalRewardModel? {
        return switch self.rewardType {
            case "chest":
                let chest = ChestBountyModel
                LocalRewardModel.chest(model: ChestBountyModel)
            case "resource":
                LocalRewardModel.standart(model: QuestRewardModel)
            default:
                return nil
        }
    }
}
