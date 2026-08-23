//
//  RemoteChestModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.05.2026.
//

struct RemoteChestModel: Decodable {
    let id: String?
    let chestName: RemoteLocalizedText?
    let version: Int?
    let visuals: RemoteChestVisuals?
    let economy: RemoteChestEconomy?
    let gradientHexBackgroundColors: [String]?
    let textHexColor: String?
    /// Adventure road styling; when absent the road derives colors from `gradientHexBackgroundColors`
    let roadColorHex: String?
    let cardGradientHexes: [String]?
    let cardTextColorHex: String?
}

struct RemoteChestVisuals: Decodable {
    let closedImagePath: String?
    let openImagePath: String?
}
