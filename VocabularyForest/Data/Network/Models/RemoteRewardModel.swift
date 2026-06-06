//
//  RemoteRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import SwiftUI

// TODO: VERSION CONTROL WILL ADD INTO RESOURCE
// MARK: - REMOTE REWARD MODEL

/// The raw data model that strictly mirrors the remote JSON structure.
/// Everything is optional to prevent decoding failures if the backend sends incomplete data.
struct RemoteRewardModel: Decodable, Identifiable {
    let id: String?
    let type: String?             // e.g., "chest" or "resource"
    let category: String?         // e.g., "gold", "nature", "water", "diamond"
    let rewardCount: Int?
    let assetName: String? // Name of the source
    let displayName: RemoteLocalizedText? // Localization key instead of raw text
    let imageSource: String? // local, remote, zip
    let localImageName: String?
    let remoteAssetVersion: Int?
    let remotePath: String?
    let posterIconPath: String? // remote den poster pathi
    let textColorHex: String?
    let gradientHexes: [String]?
    let textStrokeColorHex: String?
}
/*
extension RemoteRewardModel {
    func convertLocalReward() -> LocalRewardModel? {
        if let id = self.id, let type = self.type, let category = self.category, let rewardCount = self.rewardCount, let displayName = self.displayName, let imageSource = self.imageSource {
            var localRewardType: LocalRewardType
            switch type {
                case "standart":
                    localRewardType = LocalRewardType.standart(
                        model: LocalQuestRewardModel(
                            id: id,
                            category: QuestRewardModel.convertQuestReward(value: category),
                            displayName: displayName,
                            imageSource: imageSource,
                            posterImage: posterImage,
                            remotePath: remoteReward.remotePath,
                            textColorHex: remoteReward.textColorHex,
                            gradientHexes: remoteReward.gradientHexes
                        )
                    )
                case "chest":
                guard let chest = chestRepository.getLocalChest(chestId: id) else { return Resource.error(error: RewardRepositoryError.emptyChest) }
                localRewardType = LocalRewardType.chest(model: chest)
            default:
                return Resource.error(error: RewardRepositoryError.emptyTypeError)
            }
            let model = LocalRewardModel(rewardCount: rewardCount, reward: LocalRewardType.)
        }
    }
}
*/

// MARK: - SAFE COMPUTED PROPERTIES (UI HELPERS)

extension RemoteRewardModel {
    
    // MARK: Basic Properties
    
    var safeID: String {
        return id ?? UUID().uuidString
    }
    
    var isChestReward: Bool {
        return (type ?? "resource") == "chest"
    }
    
    var safeRewardCount: Int {
        return rewardCount ?? 1
    }
    
    var safeName: String {
        let key = displayName?.localized ?? "reward_unknown"
        return String(localized: String.LocalizationValue(key))
    }
    
    var safeImageName: String {
        return localImageName ?? "questionmark.circle.fill"
    }
    
    // MARK: Styling Properties
    
    var textColor: Color {
        guard let hex = textColorHex, !hex.isEmpty else {
            return Color.white
        }
        return Color(hex: hex)
    }
    
    var gradientBackground: AnyView {
        let colors: [Color]
        
        if let hexes = gradientHexes, !hexes.isEmpty {
            colors = hexes.map { Color(hex: $0) }
        } else {
            colors = [
                Color.gray.opacity(0.8),
                Color.gray.opacity(0.5)
            ]
        }
        
        return AnyView(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: Formatted Texts
    
    var amountText: String {
        if isChestReward {
            return safeName
        } else {
            return "\(safeName) \(safeRewardCount)"
        }
    }
}
