//
//  ChestVisualImageProvider.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.05.2026.
//

import SwiftUI
import UIKit

enum ChestVisualImageProvider {
    private static let storage = ChestVisualStorage()

    static func image(for chest: ChestBountyModel, status: ChestStatus) -> Image {
        if let uiImage = uiImage(for: chest, status: status) {
            return Image(uiImage: uiImage)
        }
        return Image(chest.getChestImage(status: status))
    }

    static func image(forChestID chestID: String, fallbackChest: ChestBountyModel, status: ChestStatus) -> Image {
        if let remotePath = remotePath(forChestID: chestID, status: status),
           let localPath = storage.localImagePath(for: remotePath),
           let image = UIImage(contentsOfFile: localPath) {
            return Image(uiImage: image)
        }
        return image(for: fallbackChest, status: status)
    }

    static func uiImage(for chest: ChestBountyModel, status: ChestStatus) -> UIImage? {
        guard let remotePath = remotePath(for: chest, status: status),
              let localPath = storage.localImagePath(for: remotePath),
              let image = UIImage(contentsOfFile: localPath) else {
            return nil
        }
        return image
    }
}

private extension ChestVisualImageProvider {
    static func remotePath(for chest: ChestBountyModel, status: ChestStatus) -> String? {
        guard let config = GameManager.snapshotChestRewardsConfig(),
              let visual = config.visuals.first(where: {
                  $0.chestType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == chest.chestTypeKey
              }) else {
            return nil
        }

        return status == .open ? visual.openImagePath : visual.closedImagePath
    }

    static func remotePath(forChestID chestID: String, status: ChestStatus) -> String? {
        let normalizedID = chestID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedID.isEmpty,
              let config = GameManager.snapshotChestRewardsConfig(),
              let visual = config.visuals.first(where: {
                  $0.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedID
              }) else {
            return nil
        }

        return status == .open ? visual.openImagePath : visual.closedImagePath
    }
}
