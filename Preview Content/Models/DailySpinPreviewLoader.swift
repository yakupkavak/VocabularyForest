#if DEBUG
//
//  DailySpinPreviewLoader.swift
//  VocabularyForest
//
//  Created by Codex on 7.07.2026.
//

import SwiftUI
import YKSpinWheel

enum DailySpinPreviewDataSource {
    static func makeModels() -> [SpinModel] {
        DailySpinPreviewLoader.loadModels()
    }
}

private enum DailySpinPreviewLoader {
    static func loadModels() -> [SpinModel] {
        do {
            let dailySpinConfig: RemoteDailySpinListModel = try decodeJSON(named: "daily_spin_rewards_config")
            let chestConfig: RemoteChestConfigResponse? = try? decodeJSON(named: "chest_rewards_config")
            let chests: [RemoteChestModel] = chestConfig?.chests ?? []
            let chestMap: [String: RemoteChestModel] = Dictionary(
                uniqueKeysWithValues: chests.compactMap { chest in
                    guard let id = chest.id else { return nil }
                    return (id, chest)
                }
            )
            
            let models = (dailySpinConfig.items ?? []).compactMap { item in
                makeSpinModel(from: item, chestMap: chestMap)
            }
            
            return models.isEmpty ? fallbackModels : models
        } catch {
            print("DailySpin preview data could not be decoded: \(error.localizedDescription)")
            return fallbackModels
        }
    }
}

private extension DailySpinPreviewLoader {
    static var fallbackModels: [SpinModel] {
        [
            SpinModel(
                id: 1,
                text: "Gold Chest",
                customImage: DailySpinPreviewIconView(assetName: "gold_chest_close")
                    .frame(width: UIScreen.main.bounds.height * 0.05, height: UIScreen.main.bounds.height * 0.05),
                weight: 3,
                textColor: "#FFFFFF".color,
                background: makeGradient(hexes: ["#FFD700", "#FF8C00"])
            ),
            SpinModel(
                id: 4,
                text: "Diamond Chest",
                customImage: DailySpinPreviewIconView(assetName: "diamond_chest_close")
                    .frame(width: UIScreen.main.bounds.height * 0.05, height: UIScreen.main.bounds.height * 0.05),
                weight: 0.6,
                textColor: "#FFFFFF".color,
                background: makeGradient(hexes: ["#00FFFF", "#4682B4"])
            ),
            SpinModel(
                id: 5,
                text: "450 Gold",
                customImage: DailySpinPreviewIconView(assetName: "gold_icon")
                    .frame(width: UIScreen.main.bounds.height * 0.05, height: UIScreen.main.bounds.height * 0.05),
                weight: 5,
                textColor: "#000000".color,
                background: makeGradient(hexes: ["#FFFACD", "#FFD700"])
            ),
            SpinModel(
                id: 6,
                text: "20 Drops",
                customImage: DailySpinPreviewIconView(assetName: "water_icon")
                    .frame(width: UIScreen.main.bounds.height * 0.05, height: UIScreen.main.bounds.height * 0.05),
                weight: 6,
                textColor: "#FFFFFF".color,
                background: makeGradient(hexes: ["#87CEFA", "#1E90FF"])
            )
        ]
    }
    
    static func makeSpinModel(
        from item: RemoteDailySpinModel,
        chestMap: [String: RemoteChestModel]
    ) -> SpinModel? {
        guard let id = item.id, let reward = item.reward else {
            return nil
        }
        
        let linkedChest = reward.chestId.flatMap { chestMap[$0] }
        let title = item.text?.localized
            ?? reward.displayName?.localized
            ?? linkedChest?.chestName?.localized
            ?? "Reward"
        let iconView = DailySpinPreviewIconView(
            assetName: assetName(for: reward, chest: linkedChest),
            systemName: "questionmark.circle.fill"
        )
        .frame(width: UIScreen.main.bounds.height * 0.05, height: UIScreen.main.bounds.height * 0.05)
        
        return SpinModel(
            id: id,
            text: title,
            customImage: iconView,
            weight: item.weight ?? 1,
            textColor: textColor(for: item, reward: reward, chest: linkedChest),
            background: background(for: item, reward: reward, chest: linkedChest)
        )
    }
    
    static func assetName(for reward: RemoteRewardModel, chest: RemoteChestModel?) -> String? {
        if reward.type == "chest" {
            if let closedImagePath = chest?.visuals?.closedImagePath {
                return URL(fileURLWithPath: closedImagePath)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            
            switch reward.category?.lowercased() {
            case "gold":
                return "gold_chest_close"
            case "diamond":
                return "diamond_chest_close"
            case "nature":
                return "nature_chest_close"
            case "antique":
                return "antique_chest_close"
            default:
                return nil
            }
        }
        
        return reward.localImageName ?? reward.assetName
    }
    
    static func textColor(
        for item: RemoteDailySpinModel,
        reward: RemoteRewardModel,
        chest: RemoteChestModel?
    ) -> Color? {
        let hex = item.textColorHex
            ?? chest?.textHexColor
            ?? reward.textColorHex
        
        return hex?.color
    }
    
    static func background(
        for item: RemoteDailySpinModel,
        reward: RemoteRewardModel,
        chest: RemoteChestModel?
    ) -> some View {
        let hexes = item.backgroundHexes
            ?? chest?.gradientHexBackgroundColors
            ?? reward.gradientHexes
            ?? fallbackHexes(for: reward)
        
        return makeGradient(hexes: hexes)
    }
    
    static func fallbackHexes(for reward: RemoteRewardModel) -> [String] {
        switch reward.category?.lowercased() {
        case "gold":
            return ["#FFF1BF", "#FFCC4D", "#B67F1E"]
        case "diamond":
            return ["#F0FDFF", "#8BE9F7", "#2783D7"]
        case "water":
            return ["#E7FAFF", "#7ADAF2", "#317DA0"]
        case "nature":
            return ["#F2FFD5", "#A8EA6A", "#4D922A"]
        case "antique":
            return ["#FFE3F1", "#FF8EC6", "#8A4DFF"]
        default:
            return ["#DADADA", "#A0A0A0"]
        }
    }
    
    static func makeGradient(hexes: [String]) -> LinearGradient {
        let colors = hexes.map { $0.color }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func decodeJSON<T: Decodable>(named name: String) throws -> T {
        let dataURL = previewContentDirectory
            .appendingPathComponent("Data")
            .appendingPathComponent("RemoteConfig")
            .appendingPathComponent("\(name).json")
        let data = try Data(contentsOf: dataURL)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    static var previewContentDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct DailySpinPreviewIconView: View {
    let assetName: String?
    let systemName: String
    
    init(assetName: String?, systemName: String = "questionmark.circle.fill") {
        self.assetName = assetName
        self.systemName = systemName
    }
    
    var body: some View {
        Group {
            if let assetName, !assetName.isEmpty {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
            }
        }
    }
}
#endif
