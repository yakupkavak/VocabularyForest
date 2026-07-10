//
//  MarketUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.07.2026.
//

import SwiftUI

// MARK: - CARD STYLE

/// Maps the reward content to a vivid color palette per category
private enum MarketCardStyle {
    case animal
    case plant
    case sculpture
    case chest(gradientHexes: [String]?)
    case exchange
    case fallback
    
    init(reward: LocalRewardModel) {
        switch reward.reward {
        case .standart(let model):
            switch model.category {
            case .animal:
                self = .animal
            case .plant:
                self = .plant
            case .sculpture:
                self = .sculpture
            case .diamond, .gold, .water:
                self = .exchange
            }
        case .chest(let model):
            self = .chest(gradientHexes: model.backgroundGradientColors)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .animal:
            [Color(hex: "#FF9F45"), Color(hex: "#E4572E")]
        case .plant:
            [Color(hex: "#7ED957"), Color(hex: "#1E8449")]
        case .sculpture:
            [Color(hex: "#B983FF"), Color(hex: "#5B2A86")]
        case .chest(let hexes):
            if let hexes, !hexes.isEmpty {
                hexes.map { $0.color }
            } else {
                [Color(hex: "#FFD700"), Color(hex: "#FF8C00")]
            }
        case .exchange:
            [Color(hex: "#4FC3F7"), Color(hex: "#1565C0")]
        case .fallback:
            [Color(hex: "#8A5E35"), Color(hex: "#5C3D20")]
        }
    }
    
    var glowColor: Color {
        gradientColors.first ?? .white
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
    let onChestInfoRequest: (String) async -> [ChestDropInfoModel]?
    
    @Environment(\.safeAreaInsets) private var globalSafeArea
    @State private var infoChest: LocalChestModel?
    @State private var infoDrops: [ChestDropInfoModel]?
    @State private var isLoadingInfo = false
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let safeBottomInset = geometry.safeAreaInsets.bottom
            let horizontalPadding = width * 0.05
            let cardWidth = min(width * 0.34, 160)
            
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                backgroundSparkles(width: width, height: height)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: width * 0.045) {
                        headerBar(width: width)
                            .padding(.horizontal, horizontalPadding)
                        
                        if let errorMessage {
                            errorBanner(message: errorMessage, width: width)
                                .padding(.horizontal, horizontalPadding)
                        }
                        
                        LazyVStack(alignment: .leading, spacing: width * 0.05) {
                            ForEach(screenModel.sections) { section in
                                sectionView(
                                    section: section,
                                    cardWidth: cardWidth,
                                    width: width,
                                    horizontalPadding: horizontalPadding
                                )
                            }
                        }
                    }
                    .padding(.bottom, safeBottomInset + width * 0.06)
                }
                .padding(.top, globalSafeArea.top > 0 ? globalSafeArea.top : width * 0.04)
                
                if infoChest != nil || isLoadingInfo {
                    chestInfoOverlay(width: width, height: height)
                        .zIndex(2)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - UI COMPONENTS

private extension MarketUI {
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.74, green: 0.88, blue: 0.55),
                Color(red: 0.16, green: 0.56, blue: 0.33),
                Color(red: 0.07, green: 0.33, blue: 0.24)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    func backgroundSparkles(width: CGFloat, height: CGFloat) -> some View {
        SparklesView(
            spreadDiameter: width * 0.9,
            primaryColor: Color(hex: "#FFF6C0"),
            secondaryColor: Color(hex: "#B7F5A8")
        )
        .opacity(0.4)
        .offset(y: height * 0.32)
        .allowsHitTesting(false)
    }
    
    func headerBar(width: CGFloat) -> some View {
        VStack(spacing: width * 0.035) {
            HStack {
                Button {
                    isVisible = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: width * 0.045, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.72))
                        .frame(width: width * 0.11, height: width * 0.11)
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                HStack(spacing: width * 0.025) {
                    balanceBadge(iconName: MarketCurrency.gold.iconName, amount: goldBalance, width: width)
                    balanceBadge(iconName: MarketCurrency.diamond.iconName, amount: diamondBalance, width: width)
                }
            }
            
            ZStack {
                Image("title_header")
                    .resizable()
                    .scaledToFit()
                    .frame(height: width * 0.14)
                
                Text(screenModel.title)
                    .font(.system(size: width * 0.065, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
            }
        }
    }
    
    func balanceBadge(iconName: String, amount: Int, width: CGFloat) -> some View {
        HStack(spacing: width * 0.015) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.045, height: width * 0.045)
            Text("\(amount)")
                .font(.system(size: width * 0.035, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.vertical, width * 0.018)
        .padding(.horizontal, width * 0.03)
        .background(Color.black.opacity(0.32))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: amount)
    }
    
    func errorBanner(message: String, width: CGFloat) -> some View {
        HStack(spacing: width * 0.02) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.system(size: width * 0.034, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(width * 0.03)
        .background(Color.red.opacity(0.55))
        .cornerRadius(14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    func sectionView(section: MarketSectionModel, cardWidth: CGFloat, width: CGFloat, horizontalPadding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: width * 0.025) {
            ZStack {
                Image("title_header")
                    .resizable()
                    .scaledToFit()
                    .frame(height: width * 0.1)
                
                Text(section.title)
                    .font(.system(size: width * 0.042, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 1)
            }
            .padding(.leading, horizontalPadding)
            
            /// Full-width scroll with edge padding so the last card is not clipped by the section inset
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: width * 0.03) {
                    ForEach(section.items) { item in
                        MarketItemCard(
                            item: item,
                            cardWidth: cardWidth,
                            canAfford: canAfford(item: item),
                            onPurchase: onPurchase,
                            onInfoTap: { chest in
                                showChestInfo(chest: chest)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, horizontalPadding)
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
    
    func showChestInfo(chest: LocalChestModel) {
        isLoadingInfo = true
        infoChest = chest
        infoDrops = nil
        Task {
            let drops = await onChestInfoRequest(chest.id)
            await MainActor.run {
                isLoadingInfo = false
                if let drops {
                    infoDrops = drops
                } else {
                    infoChest = nil
                }
            }
        }
    }
    
    func dismissChestInfo() {
        withAnimation(.easeOut(duration: 0.2)) {
            infoChest = nil
            infoDrops = nil
            isLoadingInfo = false
        }
    }
}

// MARK: - CHEST INFO OVERLAY

private extension MarketUI {
    
    func chestInfoOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissChestInfo()
                }
            
            if let chest = infoChest {
                ChestDropInfoCard(
                    chest: chest,
                    drops: infoDrops,
                    maxWidth: min(width * 0.85, 420),
                    maxHeight: height * 0.7,
                    onClose: { dismissChestInfo() }
                )
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: infoDrops)
    }
}

// MARK: - CHEST DROP INFO CARD

private struct ChestDropInfoCard: View {
    
    let chest: LocalChestModel
    let drops: [ChestDropInfoModel]?
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let onClose: () -> Void
    
    private var guaranteedDrops: [ChestDropInfoModel] {
        drops?.filter { $0.chancePercent == nil } ?? []
    }
    
    private var randomDrops: [ChestDropInfoModel] {
        drops?.filter { $0.chancePercent != nil } ?? []
    }
    
    private var headerGradientColors: [Color] {
        if let hexes = chest.backgroundGradientColors, !hexes.isEmpty {
            return hexes.map { $0.color }
        }
        return [Color(hex: "#FFD700"), Color(hex: "#FF8C00")]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            if let drops, !drops.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if !guaranteedDrops.isEmpty {
                            dropSection(
                                title: String(localized: "Garantili Ödüller"),
                                icon: "checkmark.seal.fill",
                                iconColor: Color(hex: "#7ED957"),
                                drops: guaranteedDrops
                            )
                        }
                        if !randomDrops.isEmpty {
                            dropSection(
                                title: String(localized: "Şans Ödülleri"),
                                icon: "dice.fill",
                                iconColor: Color(hex: "#4FC3F7"),
                                drops: randomDrops
                            )
                        }
                    }
                    .padding(16)
                }
            } else {
                ProgressView()
                    .tint(.white)
                    .padding(.vertical, 40)
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(red: 0.13, green: 0.3, blue: 0.2))
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 18, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            Button {
                onClose()
            } label: {
                Image("close_button")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .offset(x: 12, y: -12)
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            RewardImageView(asset: chest.closeLocalImagePath)
                .scaledToFit()
                .frame(width: 54, height: 54)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chest.displayName.localized)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                
                Text(String(localized: "Sandık içeriği ve çıkma oranları"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: headerGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func dropSection(title: String, icon: String, iconColor: Color, drops: [ChestDropInfoModel]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 6) {
                ForEach(drops) { drop in
                    dropRow(drop: drop)
                }
            }
        }
    }
    
    private func dropRow(drop: ChestDropInfoModel) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 44, height: 44)
                
                RewardImageView(asset: drop.reward.reward.posterImage)
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(drop.reward.reward.displayName.localized)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(drop.amountText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            
            Spacer(minLength: 4)
            
            chanceBadge(percent: drop.chancePercent)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func chanceBadge(percent: Int?) -> some View {
        if let percent {
            Text("%\(percent)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(chanceColor(percent: percent))
                )
        }
    }
    
    private func chanceColor(percent: Int) -> Color {
        switch percent {
        case ..<10:
            Color(hex: "#8E44AD")
        case 10..<25:
            Color(hex: "#C0392B")
        case 25..<50:
            Color(hex: "#D68910")
        default:
            Color(hex: "#2E86C1")
        }
    }
}

// MARK: - MARKET ITEM CARD

struct MarketItemCard: View {
    
    let item: MarketItemModel
    let cardWidth: CGFloat
    let canAfford: Bool
    let onPurchase: (MarketItemModel) -> Void
    var onInfoTap: ((LocalChestModel) -> Void)? = nil
    
    private var style: MarketCardStyle {
        MarketCardStyle(reward: item.reward)
    }
    
    private var chestModel: LocalChestModel? {
        if case .chest(let model) = item.reward.reward {
            return model
        }
        return nil
    }
    
    var body: some View {
        Button {
            onPurchase(item)
        } label: {
            VStack(spacing: cardWidth * 0.06) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: cardWidth * 0.11)
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.45), Color.white.opacity(0.1)],
                                center: .center,
                                startRadius: 4,
                                endRadius: cardWidth * 0.6
                            )
                        )
                        .frame(height: cardWidth * 0.72)
                    
                    RewardImageView(asset: item.reward.reward.posterImage)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: cardWidth * 0.62)
                        .padding(cardWidth * 0.06)
                        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
                    
                    if item.reward.rewardCount > 1 {
                        Text("x\(item.reward.rewardCount)")
                            .font(.system(size: cardWidth * 0.09, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(6)
                    }
                }
                
                Text(item.reward.reward.displayName.localized)
                    .font(.system(size: cardWidth * 0.1, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .frame(height: cardWidth * 0.26)
                
                priceTag
            }
            .padding(cardWidth * 0.08)
            .frame(width: cardWidth)
            .background(
                LinearGradient(
                    colors: style.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(cardWidth * 0.12)
            .overlay(
                RoundedRectangle(cornerRadius: cardWidth * 0.12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(canAfford ? 0.85 : 0.2), Color.white.opacity(canAfford ? 0.3 : 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: style.glowColor.opacity(canAfford ? 0.55 : 0.0), radius: 8, x: 0, y: 4)
            .opacity(canAfford ? 1.0 : 0.85)
            .saturation(canAfford ? 1.0 : 0.35)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canAfford)
        .overlay(alignment: .topLeading) {
            if let chestModel, let onInfoTap {
                Button {
                    onInfoTap(chestModel)
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: cardWidth * 0.15, weight: .semibold))
                        .foregroundStyle(.white, Color.black.opacity(0.45))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(cardWidth * 0.05)
                }
                /// Keep the info button tappable even when the purchase button is disabled
                .disabled(false)
            }
        }
    }
    
    private var priceTag: some View {
        HStack(spacing: cardWidth * 0.04) {
            Image(item.price.currency.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: cardWidth * 0.12, height: cardWidth * 0.12)
            Text("\(item.price.amount)")
                .font(.system(size: cardWidth * 0.11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, cardWidth * 0.04)
        .frame(maxWidth: .infinity)
        .background(canAfford ? Color.black.opacity(0.35) : Color.red.opacity(0.65))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
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
    let animalReward = LocalRewardModel(
        rewardCount: 1,
        reward: .standart(
            model: LocalQuestRewardModel(
                id: "preview-animal",
                category: .animal,
                displayName: .mock(en: "Cat"),
                assetName: "Cat",
                imageSource: .local,
                posterImage: RewardAssetReference(key: "Cat", source: .appAssets),
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
            ),
            MarketSectionModel(
                id: "preview-animals",
                title: "Hayvanlar",
                items: [
                    MarketItemModel(
                        id: "preview-animal-item",
                        price: MarketPriceModel(currency: .diamond, amount: 100),
                        reward: animalReward
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
        onPurchase: { _ in },
        onChestInfoRequest: { _ in nil }
    )
}
