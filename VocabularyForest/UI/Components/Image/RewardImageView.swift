//
//  RewardImageView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.06.2026.
//

import SwiftUI

struct RewardImageView: View {
    let asset: RewardAssetReference
    
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
    }
    
    private func loadOfflineImage(named imageName: String) -> UIImage? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        
        let fileURL = appSupport.appendingPathComponent("OfflineGameAssets").appendingPathComponent("\(imageName).png")
        return UIImage(contentsOfFile: fileURL.path)
    }
}
