//
//  RemoteRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.04.2026.
//

import SwiftUI

// MARK: - REMOTE REWARD MODEL

/// The raw data model that strictly mirrors the remote JSON structure.
/// Everything is optional to prevent decoding failures if the backend sends incomplete data.
struct RemoteRewardModel: Decodable, Identifiable {
    let id: String?
    let type: String?             // e.g., "chest" or "resource"
    let category: String?         // e.g., "gold", "nature", "water", "diamond"
    let rewardCount: Int?
    let nameKey: String?          // Localization key instead of raw text
    let displayName: RemoteLocalizedText?
    let imageName: String?
    let imagePath: String?
    let chestID: String?
    let mediaSourceType: String?
    let mediaFileType: String?
    let previewImageURL: String?
    let sourceFieldKey: String?
    let sourceVersion: String?
    let probabilityWeight: Double?
    let textColorHex: String?
    let gradientHexes: [String]?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case category
        case rewardCount
        case nameKey
        case displayName
        case imageName
        case imagePath
        case imagePathSnake = "image_path"
        case chestID
        case chestId
        case chestIDSnake = "chest_id"
        case mediaSourceType
        case mediaFileType
        case previewImageURL
        case sourceFieldKey
        case sourceVersion
        case probabilityWeight
        case textColorHex
        case gradientHexes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .rewardCount) {
            rewardCount = intValue
        } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .rewardCount) {
            rewardCount = Int(doubleValue)
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .rewardCount),
                  let parsed = Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            rewardCount = parsed
        } else {
            rewardCount = nil
        }
        nameKey = try container.decodeIfPresent(String.self, forKey: .nameKey)
        displayName = try container.decodeIfPresent(RemoteLocalizedText.self, forKey: .displayName)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)

        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
            ?? container.decodeIfPresent(String.self, forKey: .imagePathSnake)
        chestID = try container.decodeIfPresent(String.self, forKey: .chestID)
            ?? container.decodeIfPresent(String.self, forKey: .chestId)
            ?? container.decodeIfPresent(String.self, forKey: .chestIDSnake)

        mediaSourceType = try container.decodeIfPresent(String.self, forKey: .mediaSourceType)
        mediaFileType = try container.decodeIfPresent(String.self, forKey: .mediaFileType)
        previewImageURL = try container.decodeIfPresent(String.self, forKey: .previewImageURL)
        sourceFieldKey = try container.decodeIfPresent(String.self, forKey: .sourceFieldKey)
        sourceVersion = try container.decodeIfPresent(String.self, forKey: .sourceVersion)
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .probabilityWeight) {
            probabilityWeight = doubleValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .probabilityWeight) {
            probabilityWeight = Double(intValue)
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .probabilityWeight),
                  let parsed = Double(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            probabilityWeight = parsed
        } else {
            probabilityWeight = nil
        }
        textColorHex = try container.decodeIfPresent(String.self, forKey: .textColorHex)
        gradientHexes = try container.decodeIfPresent([String].self, forKey: .gradientHexes)
    }
}

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
        if let localizedName = displayName?.resolved(), !localizedName.isEmpty {
            return localizedName
        }
        return nameKey ?? "Reward"
    }
    
    var safeImageName: String {
        return imageName ?? "questionmark.circle.fill"
    }
    
    var safeProbabilityWeight: Double {
        return probabilityWeight ?? 1.0
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
