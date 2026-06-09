//
//  MockLocalQuestRewardModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.06.2026.
//

@testable import VocabularyForest

extension LocalQuestRewardModel {
    static func mock(
        id: String = "mock_1",
        category: QuestRewardModel = .gold,
        assetName: String = "mock_icon"
    ) -> LocalQuestRewardModel {
        return LocalQuestRewardModel(
            id: id,
            category: category,
            displayName: RemoteLocalizedText(tr: "Altın", en: "Gold", es: nil, fr: nil, de: nil, pt: nil),
            assetName: assetName,
            imageSource: .local,
            posterImage: RewardAssetReference(key: "mock_poster", source: .appAssets),
            remotePath: nil,
            remoteAssetVersion: nil,
            textColorHex: nil,
            textStrokeColorHex: nil,
            gradientHexes: nil
        )
    }
}
