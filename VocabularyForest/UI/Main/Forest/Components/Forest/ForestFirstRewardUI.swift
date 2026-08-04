//
//  ForestFirstRewardUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.06.2026.
//

import SwiftUI

struct ForestFirstRewardUI: View {
    
    // MARK: - PROPERTIES
    
    let rewards: [LocalRewardModel]
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    let selectedReward: (LocalRewardModel) -> Void
    
    // MARK: - VIEW
    
    var body: some View {
        VStack {
            Text("Welcome to your forest")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .foregroundStyle(.darkGren)
                .fontWeight(.heavy)
                .padding(.vertical, 4)
                .font(.system(size: 20))
            Text("Chose your best friend to start the adventure!")
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .foregroundStyle(.brown300)
                .fontWeight(.bold)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(rewards.prefix(3), id: \.self) { reward in
                    rewardView(reward: reward).onTapGesture {
                        selectedReward(reward)
                    }
                }
            }
            .padding()
        }
        .padding(8)
        .background(.white.opacity(0.4))
        .borderShape(radius: 20)
        .padding(.horizontal)

    }
}

private extension ForestFirstRewardUI {
    
    @ViewBuilder
    func rewardView(reward: LocalRewardModel) -> some View {
        VStack(spacing: 20) {
            RewardImageView(asset: reward.reward.posterImage).scaledToFit()
            Text(reward.reward.displayName.localized).lineLimit(1)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .fontWeight(.heavy)
        }.padding().padding(.top, -8)
            .background(AnimatedGradientView(colors: [.forestText.opacity(0.6), .forestText.opacity(0.7), .forestText.opacity(0.8), .forestText.opacity(0.6)]))
            .clipShape(RoundedRectangle(cornerRadius: 16)
            )
    }
}

#Preview("Standart") {
    let rewards: [LocalRewardModel] = [
        LocalRewardModel(rewardCount: 1, reward: .standart(model: .init(id: "initalize_dog_id", category: .animal, displayName: RemoteLocalizedText.mock(en: "Dog"), assetName: "Dog", imageSource: .local, posterImage: RewardAssetReference(key: "Dog", source: .appAssets), remotePath: nil, remoteAssetVersion: nil, textColorHex: nil, textStrokeColorHex: nil, gradientHexes: nil))),
        LocalRewardModel(rewardCount: 1, reward: .standart(model: .init(id: "initalize_whitecat_id", category: .animal, displayName: RemoteLocalizedText.mock(en: "WhiteCat"), assetName: "WhiteCat", imageSource: .local, posterImage: RewardAssetReference(key: "WhiteCat", source: .appAssets), remotePath: nil, remoteAssetVersion: nil, textColorHex: nil, textStrokeColorHex: nil, gradientHexes: nil))),
        LocalRewardModel(rewardCount: 1, reward: .standart(model: .init(id: "initalize_cat_id", category: .animal, displayName: RemoteLocalizedText.mock(en: "Cat"), assetName: "Cat", imageSource: .local, posterImage: RewardAssetReference(key: "Cat", source: .appAssets), remotePath: nil, remoteAssetVersion: nil, textColorHex: nil, textStrokeColorHex: nil, gradientHexes: nil)))
    ]
    ForestFirstRewardUI(rewards: rewards, selectedReward: { _ in })
}
