//
//  ForestConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.01.2026.
//

import Foundation

enum ForestConstant {
    /// Scene menu column geometry — single source shared by EnvironmentManager
    /// (SpriteKit, bottom-left origin) and ForestUI's tap/accessibility overlay
    /// (SwiftUI, top-left origin: y = 1 - value). Keeping both layers on the
    /// same fractions is what makes Voice Control's synthetic taps land on the
    /// real buttons on every screen size.
    static let menuButtonRelativeX: CGFloat = 0.90
    static let menuButtonRelativeYs: [CGFloat] = [0.90, 0.83, 0.76, 0.69, 0.62]
    static let menuButtonRelativeSize: CGFloat = 0.05
    /// Minimum 44x44pt touch target; 0.05*H drops below it on small phones.
    static let menuButtonMinSize: CGFloat = 44
    static let rightIconName = "right_icon"
    static let leftIconName = "left_icon"
    static let downIconName = "down_icon"
    static let upIconName = "up_icon"
    static let confirmIconName = "accept_button"
    static let refuseIconName = "close_button"
    static let perHorizontalMove: CGFloat = 0.01
    static let perVerticalMove: CGFloat = 0.04
    static let allButtons = [rightIconName, leftIconName, downIconName, upIconName, confirmIconName, refuseIconName]
    static let floorName = "floorNode"
    static let sculptureName = "sculptureNode"
    static let animalName = "animalNode"
    static let plantName = "plantNode"
    /// Rain cost comes from the remote economy config; falls back to 50 until the config loads
    static var rainCostValue: Int {
        GameManager.snapshotEconomyConfig()?.progressionTargets?.rainCost ?? 50
    }
    static let healthyLandHealth = 100
    static let menu_ballon_name = ""
    static let talk_ballon_name = ""
    static let firstForestRewards: [LocalRewardModel] = [
        LocalRewardModel(
            rewardCount: 1,
            reward: .standart(model: .init(
                id: "initalize_dog_id",
                category: .animal,
                displayName: RemoteLocalizedText(
                    tr: "Köpek",
                    en: "Dog",
                    es: "Perro",
                    fr: "Chien",
                    de: "Hund",
                    pt: "Cachorro"
                ),
                assetName: "Dog",
                imageSource: .local,
                posterImage: RewardAssetReference(key: "Dog", source: .appAssets),
                remotePath: nil,
                remoteAssetVersion: nil,
                textColorHex: nil,
                textStrokeColorHex: nil,
                gradientHexes: nil
            ))
        ),
        LocalRewardModel(
            rewardCount: 1,
            reward: .standart(model: .init(
                id: "initalize_whitecat_id",
                category: .animal,
                displayName: RemoteLocalizedText(
                    tr: "Beyaz Kedi",
                    en: "White Cat",
                    es: "Gato Blanco",
                    fr: "Chat Blanc",
                    de: "Weiße Katze",
                    pt: "Gato Branco"
                ),
                assetName: "WhiteCat",
                imageSource: .local,
                posterImage: RewardAssetReference(key: "WhiteCat", source: .appAssets),
                remotePath: nil,
                remoteAssetVersion: nil,
                textColorHex: nil,
                textStrokeColorHex: nil,
                gradientHexes: nil
            ))
        ),
        LocalRewardModel(
            rewardCount: 1,
            reward: .standart(model: .init(
                id: "initalize_cat_id",
                category: .animal,
                displayName: RemoteLocalizedText(
                    tr: "Kedi",
                    en: "Cat",
                    es: "Gato",
                    fr: "Chat",
                    de: "Katze",
                    pt: "Gato"
                ),
                assetName: "Cat",
                imageSource: .local,
                posterImage: RewardAssetReference(key: "Cat", source: .appAssets),
                remotePath: nil,
                remoteAssetVersion: nil,
                textColorHex: nil,
                textStrokeColorHex: nil,
                gradientHexes: nil
            ))
        )
    ]
}


