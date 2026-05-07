//
//  RewardImageProvider.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import SwiftUI
import UIKit

enum RewardImageProvider {
    private static let rewardImageStorage = RewardImageStorage()

    static func image(
        for reward: LocalRewardModel,
        presentation: RewardPresentationModel? = nil,
        chestStatus: ChestStatus = .close
    ) -> Image {
        if let imagePath = presentation?.imagePath,
           let uiImage = uiImage(forRemotePath: imagePath) {
            return Image(uiImage: uiImage)
        }

        switch reward {
        case .chest(let chestModel):
            if let chestID = presentation?.chestID {
                return ChestVisualImageProvider.image(
                    forChestID: chestID,
                    fallbackChest: chestModel,
                    status: chestStatus
                )
            }
            return ChestVisualImageProvider.image(for: chestModel, status: chestStatus)
        case .standart(let model):
            if let fallbackPath = descriptorPreviewPath(for: model),
               let uiImage = uiImage(forRemotePath: fallbackPath) {
                return Image(uiImage: uiImage)
            }
            return Image(reward.rewardImage)
        }
    }
}

private extension RewardImageProvider {
    static func uiImage(forRemotePath path: String) -> UIImage? {
        guard let localPath = rewardImageStorage.localImagePath(for: path),
              let image = UIImage(contentsOfFile: localPath) else {
            return nil
        }
        return image
    }

    static func descriptorPreviewPath(for reward: QuestRewardModel) -> String? {
        switch reward {
        case .animal(let modelName):
            return RewardMediaCatalogStore.descriptor(category: "animal", modelKey: modelName)?.previewImageURL
        case .plant(let modelName):
            return RewardMediaCatalogStore.descriptor(category: "plant", modelKey: modelName)?.previewImageURL
        case .sculpture(let modelName):
            return RewardMediaCatalogStore.descriptor(category: "sculpture", modelKey: modelName)?.previewImageURL
        default:
            return nil
        }
    }
}
