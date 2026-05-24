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
    let shortTermReward, longTermReward: RemoteRewardModel?
}

/*
extension RemoteTermReward {
    func convertLocalReward() -> LocalRewardType? {
        return switch self.rewardType {
            case "chest":
                let chest = ChestBountyModel
                LocalRewardType.chest(model: ChestBountyModel)
            case "resource":
                LocalRewardType.standart(model: QuestRewardModel)
            default:
                return nil
        }
    }
}
*/
