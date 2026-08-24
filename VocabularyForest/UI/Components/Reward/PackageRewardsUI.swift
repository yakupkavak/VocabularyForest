//
//  PackageRewardsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import SwiftUI

// MARK: - CONSTANTS

private extension PackageRewardsUI {
    enum Constants {
        static let gridSpacing: CGFloat = 20
        static let cardCornerRadius: CGFloat = 15
        static let cardBackgroundOpacity: Double = 0.15
        static let sparkleOpacity: Double = 0.95
    }
}

// MARK: - VIEW

/// Summary shown after a package purchase: every reward is already granted,
/// so the single button only dismisses the popup.
struct PackageRewardsUI: View {

    let rewards: [LocalRewardModel]
    let onDismiss: () -> Void
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SparklesView(
                    spreadDiameter: isPad ? min(geometry.size.width * 0.6, 600) : geometry.size.width * 0.9,
                    primaryColor: .white,
                    secondaryColor: .tierS
                )
                .opacity(Constants.sparkleOpacity)

                VStack {
                    Spacer()
                    rewardsGrid(size: geometry.size)
                    Spacer()
                    dismissButton
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

// MARK: - UI COMPONENTS

private extension PackageRewardsUI {
    func rewardsGrid(size: CGSize) -> some View {
        let columns = [GridItem(.adaptive(minimum: isPad ? 150 : 100))]

        return VStack(spacing: Constants.gridSpacing) {
            Text(LocalizedStringKey("Kazanılan Ödüller"))
                .scaledFont(size: isPad ? 36 : 24, weight: .bold, design: .rounded)
                .foregroundColor(.white)
                .shadow(radius: 2)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: Constants.gridSpacing) {
                    ForEach(Array(rewards.enumerated()), id: \.offset) { _, reward in
                        rewardCell(reward)
                    }
                }
                .padding(.horizontal, Constants.gridSpacing)
            }
            .frame(maxHeight: size.height * 0.5)
        }
    }

    func rewardCell(_ reward: LocalRewardModel) -> some View {
        VStack {
            RewardImageView(asset: reward.reward.posterImage)
                .scaledToFit()
                .frame(height: isPad ? 120 : 80)

            HStack(spacing: 4) {
                if let tier = reward.reward.tier {
                    TierBadgeView(tier: tier, fontSize: isPad ? 14 : 10)
                }
                Text(LocalizedStringKey(reward.reward.displayName.localized))
                    .scaledFont(size: isPad ? 20 : 14, weight: .bold, design: .rounded)
                    .foregroundColor(.white)
            }
            if reward.rewardCount > 1 {
                Text("x\(reward.rewardCount)")
                    .scaledFont(size: isPad ? 18 : 12, weight: .bold, design: .rounded)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(Constants.cardBackgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .a11yGroup()
    }

    var dismissButton: some View {
        Button(action: onDismiss) {
            Text(LocalizedStringKey("Claim reward"))
                .scaledFont(size: isPad ? 38 : 28, weight: .black, design: .rounded)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, isPad ? 24 : 20)
                .frame(maxWidth: isPad ? 400 : .infinity)
                .background(
                    LinearGradient(colors: [.tierS, .tierSPlus], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: Color.tierS.opacity(0.5), radius: 10, x: 0, y: 10)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, isPad ? 80 : 50)
    }
}

// MARK: - PREVIEW

#Preview {
    PackageRewardsUI(
        rewards: [
            LocalRewardModel(
                rewardCount: 60,
                reward: .standart(model: LocalQuestRewardModel(
                    id: "reward-diamond",
                    category: .diamond,
                    displayName: .mock(en: "Diamond"),
                    assetName: "diamond_icon",
                    imageSource: .local,
                    posterImage: RewardAssetReference(key: "diamond_icon", source: .appAssets),
                    remotePath: nil,
                    remoteAssetVersion: nil,
                    textColorHex: nil,
                    textStrokeColorHex: nil,
                    gradientHexes: nil
                ))
            )
        ],
        onDismiss: {}
    )
    .background(Color.black)
}
