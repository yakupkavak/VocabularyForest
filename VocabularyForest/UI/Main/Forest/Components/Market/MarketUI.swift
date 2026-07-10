//
//  MarketUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.07.2026.
//

import SwiftUI

// MARK: - CONSTANTS

private extension MarketUI {
    enum LayoutConfig {
        static let contentWidthRatio: CGFloat = 0.62
        static let contentHeightRatio: CGFloat = 0.55
        static let maxContentWidth: CGFloat = 460
        static let maxContentHeight: CGFloat = 560
        static let cardWidth: CGFloat = 132
        static let cardImageHeight: CGFloat = 76
    }
}

// MARK: - MARKET UI

struct MarketUI: View {
    
    // MARK: - PROPERTIES
    
    let screenModel: MarketScreenModel
    @Binding var isVisible: Bool
    let goldBalance: Int
    let diamondBalance: Int
    let errorMessage: String?
    let onPurchase: (MarketItemModel) -> Void
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width * LayoutConfig.contentWidthRatio, LayoutConfig.maxContentWidth)
            let contentHeight = min(geometry.size.height * LayoutConfig.contentHeightRatio, LayoutConfig.maxContentHeight)
            
            GamePopUpContainer(
                title: screenModel.title,
                onClose: { isVisible = false },
                screenWidth: geometry.size.width
            ) {
                VStack(spacing: 12) {
                    balanceSection
                    
                    if let errorMessage {
                        errorBanner(message: errorMessage)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(screenModel.sections) { section in
                                sectionView(section: section)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .frame(width: contentWidth, height: contentHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - UI COMPONENTS

private extension MarketUI {
    
    var balanceSection: some View {
        HStack(spacing: 10) {
            Spacer()
            balanceBadge(iconName: MarketCurrency.gold.iconName, amount: goldBalance)
            balanceBadge(iconName: MarketCurrency.diamond.iconName, amount: diamondBalance)
        }
    }
    
    func balanceBadge(iconName: String, amount: Int) -> some View {
        HStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text("\(amount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: amount)
    }
    
    func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.45))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    func sectionView(section: MarketSectionModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(section.items) { item in
                        MarketItemCard(
                            item: item,
                            canAfford: canAfford(item: item),
                            onPurchase: onPurchase
                        )
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
    }
    
    func canAfford(item: MarketItemModel) -> Bool {
        switch item.price.currency {
        case .gold:
            goldBalance >= item.price.amount
        case .diamond:
            diamondBalance >= item.price.amount
        }
    }
}

// MARK: - MARKET ITEM CARD

struct MarketItemCard: View {
    
    let item: MarketItemModel
    let canAfford: Bool
    let onPurchase: (MarketItemModel) -> Void
    
    private var cardGradientColors: [Color] {
        if let hexes = item.reward.reward.gradientHexes, !hexes.isEmpty {
            return hexes.map { $0.color }
        }
        return switch item.price.currency {
        case .gold:
            [Color(hex: "#8A5E35"), Color(hex: "#5C3D20")]
        case .diamond:
            [Color(hex: "#2E6B8A"), Color(hex: "#1C3F55")]
        }
    }
    
    var body: some View {
        Button {
            onPurchase(item)
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.16))
                        .frame(height: 88)
                    
                    RewardImageView(asset: item.reward.reward.posterImage)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 76)
                        .padding(6)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    if item.reward.rewardCount > 1 {
                        Text("x\(item.reward.rewardCount)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Capsule())
                            .padding(6)
                    }
                }
                
                Text(item.reward.reward.displayName.localized)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .frame(height: 34)
                
                priceTag
            }
            .padding(10)
            .frame(width: 132)
            .background(
                LinearGradient(
                    colors: cardGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(canAfford ? 0.35 : 0.15), lineWidth: 1.5)
            )
            .opacity(canAfford ? 1.0 : 0.55)
            .saturation(canAfford ? 1.0 : 0.4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canAfford)
    }
    
    private var priceTag: some View {
        HStack(spacing: 5) {
            Image(item.price.currency.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("\(item.price.amount)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(canAfford ? .white : .red.opacity(0.9))
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - PREVIEW

#Preview {
    let goldReward = LocalRewardModel(
        rewardCount: 10,
        reward: .standart(
            model: LocalQuestRewardModel(
                id: "preview-diamond",
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
            )
        )
    )
    let screenModel = MarketScreenModel(
        title: "Market",
        sections: [
            MarketSectionModel(
                id: "preview-exchange",
                title: "Takas",
                items: [
                    MarketItemModel(
                        id: "preview-item",
                        price: MarketPriceModel(currency: .gold, amount: 1000),
                        reward: goldReward
                    )
                ]
            )
        ]
    )
    MarketUI(
        screenModel: screenModel,
        isVisible: .constant(true),
        goldBalance: 1500,
        diamondBalance: 42,
        errorMessage: nil,
        onPurchase: { _ in }
    )
}
