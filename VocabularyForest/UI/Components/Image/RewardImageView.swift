//
//  RewardImageView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.06.2026.
//

import SwiftUI

struct RewardImageView: View {
    let asset: RewardAssetReference
    /// Spoken description of the reward; without it VoiceOver would read the
    /// remote-config asset key, so unlabeled instances are hidden instead.
    var label: String? = nil

    var body: some View {
        Group {
            switch asset.source {
            case .appAssets:
                Image(asset.key)
                    .resizable()
            case .offlineStorage:
                if let uiImage = loadOfflineImage(named: asset.key) {
                    Image(uiImage: uiImage)
                        .resizable()
                } else {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
        }
        .modifier(RewardImageAccessibility(label: label))
    }
    
    private func loadOfflineImage(named imageName: String) -> UIImage? {
            let fileManager = FileManager.default
            guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
            let cleanName = imageName.replacingOccurrences(of: ".png", with: "")
            let fileURL = appSupport.appendingPathComponent("OfflineGameAssets").appendingPathComponent("\(cleanName).png")
            
            do {
                let data = try Data(contentsOf: fileURL)
                return UIImage(data: data)
            } catch {
                AppLogger.shared.debug("Reward image not found on disk at \(fileURL.path)", category: .asset)
                return nil
            }
        }
}

// MARK: - HELPERS

private struct RewardImageAccessibility: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        if let label {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
        } else {
            content.a11yDecorative()
        }
    }
}
