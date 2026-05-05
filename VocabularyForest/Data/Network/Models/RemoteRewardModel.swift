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
struct RemoteRewardModel: Codable, Identifiable {
    let id: String?
    let type: String?             // e.g., "chest" or "resource"
    let category: String?         // e.g., "gold", "nature", "water", "diamond"
    let rewardCount: Int?
    let nameKey: String?          // Localization key instead of raw text
    let imageName: String?
    let mediaSourceType: String?
    let mediaFileType: String?
    let previewImageURL: String?
    let sourceFieldKey: String?
    let sourceVersion: String?
    let probabilityWeight: Double?
    let textColorHex: String?
    let gradientHexes: [String]?
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
        let key = nameKey ?? "reward_unknown"
        return String(localized: String.LocalizationValue(key))
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
