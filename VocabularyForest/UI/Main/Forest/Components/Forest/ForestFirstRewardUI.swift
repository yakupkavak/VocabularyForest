//
//  ForestFirstRewardUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.06.2026.
//

import SwiftUI

// MARK: - CONSTANTS

private extension ForestFirstRewardUI {
    enum Constants {
        static let visibleRewardCount: Int = 3
        static let cardSpacing: CGFloat = 12
        static let scrollVerticalPadding: CGFloat = 8
        /// Uniform poster box: with a cap instead, a wide asset (Dog) reports a shorter box
        /// than a tall one (Cat) and the images stop lining up across cards.
        static let posterHeight: CGFloat = 72
        static let cardContentSpacing: CGFloat = 20
        static let cardCornerRadius: CGFloat = 16
        static let cardTopInset: CGFloat = -8
        static let containerCornerRadius: CGFloat = 20
        static let containerOpacity: Double = 0.4
        static let containerPadding: CGFloat = 8
        static let titleFontSize: CGFloat = 20
        static let titleLineLimit: Int = 2
        static let titleScaleFactor: CGFloat = 0.8
        static let nameLineLimit: Int = 2
        static let nameScaleFactor: CGFloat = 0.6
        static let titlePadding: CGFloat = 4
        static let gradientOpacities: [Double] = [0.6, 0.7, 0.8, 0.6]
    }
}

// MARK: - VIEW

struct ForestFirstRewardUI: View {

    // MARK: - PROPERTIES

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    let rewards: [LocalRewardModel]
    let selectedReward: (LocalRewardModel) -> Void

    // MARK: - VIEW

    /// The panel grows with Dynamic Type, so at the largest sizes it can outgrow the screen;
    /// the scrolling variant only kicks in once the plain one no longer fits.
    var body: some View {
        ViewThatFits(in: .vertical) {
            panel
            // The forest is presented with .ignoresSafeArea, so a GeometryReader in here reads
            // zero insets; the scrolling panel has to take them from the environment instead.
            ScrollView {
                panel.padding(.vertical, Constants.scrollVerticalPadding)
            }
            .padding(.top, safeAreaInsets.top)
            .padding(.bottom, safeAreaInsets.bottom)
        }
    }
}

// MARK: - UI COMPONENTS

private extension ForestFirstRewardUI {

    var panel: some View {
        VStack {
            Text("Welcome to your forest")
                .lineLimit(Constants.titleLineLimit)
                .minimumScaleFactor(Constants.titleScaleFactor)
                .multilineTextAlignment(.center)
                .foregroundStyle(.darkGren)
                .fontWeight(.heavy)
                .padding(.vertical, Constants.titlePadding)
                .scaledFont(size: Constants.titleFontSize)
            Text("Chose your best friend to start the adventure!")
                .minimumScaleFactor(Constants.titleScaleFactor)
                .multilineTextAlignment(.center)
                .foregroundStyle(.brown300)
                .fontWeight(.bold)
            cardStack
                // Without this the cards' maxHeight fill reads as greedy and they stretch to
                // the whole screen instead of to each other.
                .fixedSize(horizontal: false, vertical: true)
                .padding()
        }
        .padding(Constants.containerPadding)
        .background(.white.opacity(Constants.containerOpacity))
        .borderShape(radius: Constants.containerCornerRadius)
        .padding(.horizontal)
    }

    /// Side by side the three cards share the height of the tallest one. At accessibility text
    /// sizes that layout leaves each name about a third of the panel — too narrow for a longer
    /// translation like "Weiße Katze", which then breaks mid-word — so the cards reflow into a
    /// single column and each name gets the full width.
    @ViewBuilder
    var cardStack: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Constants.cardSpacing) { cards }
        } else {
            HStack(spacing: Constants.cardSpacing) { cards }
        }
    }

    var cards: some View {
        ForEach(rewards.prefix(Constants.visibleRewardCount), id: \.self) { reward in
            rewardView(reward: reward).onTapGesture {
                selectedReward(reward)
            }
        }
    }

    /// All three cards end up the same size: each one fills the HStack, whose height comes from
    /// the tallest card. Only the poster box is fixed — the name is free to take the height it
    /// needs, so a wrapping name (like "White Cat") grows all three cards together instead of
    /// just its own, and larger Dynamic Type sizes are absorbed rather than clipped.
    @ViewBuilder
    func rewardView(reward: LocalRewardModel) -> some View {
        VStack(spacing: Constants.cardContentSpacing) {
            RewardImageView(asset: reward.reward.posterImage)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: Constants.posterHeight)
            Text(reward.reward.displayName.localized)
                .lineLimit(Constants.nameLineLimit)
                .minimumScaleFactor(Constants.nameScaleFactor)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .fontWeight(.heavy)
        }
        .padding()
        .padding(.top, Constants.cardTopInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnimatedGradientView(colors: Constants.gradientOpacities.map { Color.forestText.opacity($0) }))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
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
