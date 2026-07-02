//
//  ClaimRewardUI.swift
//  VocabularyForest
// 
//  Created by Yakup Kavak on 20.04.2026.
//

import SwiftUI
import Combine

// MARK: - CLAIM REWARD UI

struct ClaimRewardUI: View {
    
    // MARK: - PROPERTIES
    
    @ObservedObject var viewModel: ClaimRewardViewModel
    var claimReward: LocalRewardModel
    var onClaim: ([LocalRewardModel]) -> Void
    @State private var shakeOffset: CGFloat = 0
    @State private var showClaim = true
    @State private var chestStation: ChestStatus = .close
    @State private var chestRewardIndex = 0
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    private let claimedRewards: [LocalRewardModel] = []

    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundSection(size: geometry.size)
                
                VStack {
                    Spacer()
                    mainContentSection(size: geometry.size)
                    Spacer()
                    actionButton(size: geometry.size).opacity(showClaim ? 1 : 0)
                }
            }.task {
                if case .chest(let model) = claimReward.reward {
                    viewModel.openChest(chestID: model.id)
                }
            }
            .onReceive(timer) { _ in
                triggerShake()
            }
        }
    }
}

// MARK: - UI COMPONENTS

private extension ClaimRewardUI {
    func backgroundSection(size: CGSize) -> some View {
        let sparklePalette = currentSparklePalette()
        let sparkleSpread = isPad ? min(size.width * 0.6, 600) : size.width * 0.9
        
        return ZStack {
            SparklesView(
                spreadDiameter: sparkleSpread,
                primaryColor: sparklePalette.primary,
                secondaryColor: sparklePalette.secondary
            )
            .opacity(0.95)
            .zIndex(2)
        }
    }
    
    @ViewBuilder
    func mainContentSection(size: CGSize) -> some View {
        switch claimReward.reward {
        case .standart(let model):
            standartRewardView(model: model, size: size)
        case .chest(let chestModel):
            chestRewardView(chestModel: chestModel, size: size)
                .task {
                    showClaim = false
                }.onTapGesture {
                    openChest()
                }
        }
    }
    
    func standartRewardView(model: LocalQuestRewardModel, size: CGSize) -> some View {
        let mainImageWidth = isPad ? min(size.width * 0.35, 450) : size.width * 0.4
        let rewardTextSize: CGFloat = isPad ? 40 : 32
        
        return VStack {
            RewardImageView(asset: model.posterImage)
                .scaledToFit()
                .frame(width: mainImageWidth)
            Text(LocalizedStringKey(model.displayName.localized))
                .font(.system(size: rewardTextSize, weight: .medium, design: .rounded))
                .foregroundColor(model.textColorHex?.color)
                .shadow(color: .black.opacity(0.3), radius: 5)
        }
    }
    
    @ViewBuilder
    func chestRewardView(chestModel: LocalChestModel, size: CGSize) -> some View {
        let mainImageWidth = isPad ? min(size.width * 0.35, 450) : size.width * 0.4
        
        VStack {
            if chestStation == .open, let chestRewards = viewModel.chestRewards {
                if chestRewardIndex < chestRewards.count {
                    // 1. Durum: Ödülleri tek tek göster
                    let currentReward = chestRewards[chestRewardIndex]
                    chestRewardUI(model: currentReward, size: size)
                        .transition(.scale.combined(with: .opacity))
                        .id(chestRewardIndex) // Animasyonun tetiklenmesi için
                } else {
                    // 2. Durum: Tüm ödüllerin özeti
                    chestSummaryView(rewards: chestRewards, size: size)
                        .transition(.opacity)
                }
            } else {
                // 0. Durum: Kasa Kapalı
                RewardImageView(asset: chestModel.closeLocalImagePath)
                    .scaledToFit()
                    .frame(width: mainImageWidth)
                    .offset(x: shakeOffset)
            }
        }
    }
    
    func chestSummaryView(rewards: [LocalRewardModel], size: CGSize) -> some View {
        let columns = [GridItem(.adaptive(minimum: isPad ? 150 : 100))]
        
        return VStack(spacing: 20) {
            Text(LocalizedStringKey("Kazanılan Ödüller"))
                .font(.system(size: isPad ? 36 : 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(rewards.indices, id: \.self) { index in
                    VStack {
                        RewardImageView(asset: rewards[index].reward.posterImage)
                            .scaledToFit()
                            .frame(height: isPad ? 120 : 80)
                        
                        Text(LocalizedStringKey(rewards[index].reward.displayName.localized))
                            .font(.system(size: isPad ? 20 : 14, weight: .bold, design: .rounded))
                            .foregroundColor(rewards[index].reward.textColorHex?.color ?? .white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    func chestRewardUI(model: LocalRewardModel, size: CGSize) -> some View {
        let mainImageWidth = isPad ? min(size.width * 0.35, 450) : size.width * 0.4
        let rewardTextSize: CGFloat = isPad ? 40 : 32
        
        return VStack {
            RewardImageView(asset: model.reward.posterImage)
                .scaledToFit()
                .frame(width: mainImageWidth)
            Text(LocalizedStringKey(model.reward.displayName.localized))
                .font(.system(size: rewardTextSize, weight: .medium, design: .rounded))
                .foregroundColor(model.reward.textColorHex?.color)
                .shadow(color: .black.opacity(0.3), radius: 5)
        }
    }
    
    func actionButton(size: CGSize) -> some View {
        let buttonMaxWidth = isPad ? CGFloat(400) : .infinity
        
        // Değişkeni doğrudan LocalizedStringKey olarak tanımlıyoruz
        var buttonTitleKey: LocalizedStringKey = "Claim reward"
        
        if case .chest = claimReward.reward, let chestRewards = viewModel.chestRewards, chestStation == .open {
            if chestRewardIndex < chestRewards.count {
                buttonTitleKey = "Next"
            }
        }
        
        return Button(action: {
            handleClaim()
        }) {
            // Text içine doğrudan LocalizedStringKey veriyoruz
            Text(buttonTitleKey)
                .font(.system(size: isPad ? 38 : 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, isPad ? 24 : 20)
                .frame(maxWidth: buttonMaxWidth)
                .background(claimButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: claimButtonShadowColor.opacity(0.5), radius: 10, x: 0, y: 10)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, isPad ? 80 : 50)
    }
}

// MARK: - PRIVATE HELPERS

private extension ClaimRewardUI {
    
    func openChest() {
        chestStation = .open
        showClaim = true
    }
    
    func handleClaim() {
        if case .chest = claimReward.reward {
            if let chestRewards = viewModel.chestRewards {
                if chestRewardIndex < chestRewards.count {
                    // Sıradaki ödüle veya özet ekranına yumuşak geçiş yap
                    withAnimation(.spring()) {
                        chestRewardIndex += 1
                    }
                } else {
                    // Özet ekranındayız, tüm kasa ödüllerini topla
                    onClaim(chestRewards)
                }
            } else {
                onClaim(claimedRewards)
            }
        } else {
            // Standart tekli ödül
            onClaim([claimReward])
        }
    }
    func triggerShake() {
        if case .chest = claimReward.reward {
            withAnimation(.easeInOut(duration: 0.12).repeatCount(5, autoreverses: true)) {
                shakeOffset = 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                shakeOffset = 0
            }
        }
    }
    
    func currentSparklePalette() -> SparklePalette {
        currentRewardTheme().sparklePalette
    }
    
    func currentRewardTheme() -> RewardTheme {
        switch claimReward.reward {
        case .standart(let model):
            return model.category.theme
        case .chest(let model):
            let panelColors = model.backgroundGradientColors?.map { $0.color } ?? [
                Color(hex: "#FFF1DF"),
                Color(hex: "#D7AF7C"),
                Color(hex: "#8A5E35")
            ]
            let textColor = model.textHexColor?.color ?? Color(hex: "#6F4624")
            let strokeColor = panelColors.last ?? Color(hex: "#8A5E35")
            return RewardTheme(
                textColor: textColor,
                panelColors: panelColors,
                panelStroke: strokeColor,
                buttonColors: [panelColors.first ?? Color(hex: "#D8B08A"), panelColors.last ?? Color(hex: "#9B6A3A")],
                buttonShadow: strokeColor,
                sparklePalette: SparklePalette(
                    primary: panelColors.first ?? Color(hex: "#FFF1DF"),
                    secondary: panelColors.dropFirst().first ?? Color(hex: "#D7AF7C"),
                    shadow: strokeColor
                )
            )
        }
    }
    
    var claimButtonGradient: LinearGradient {
        LinearGradient(colors: currentRewardTheme().buttonColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var claimButtonStrokeColor: Color {
        currentRewardTheme().panelStroke
    }
    
    var claimButtonShadowColor: Color {
        currentRewardTheme().buttonShadow
    }
}

// MARK: - PREVIEW

#Preview("Chest") {
    ClaimRewardUI(viewModel: ClaimRewardViewModel(chestManager: ChestRepository(assetManager: OfflineAssetManager(), apiService: APIService())),claimReward: LocalRewardModel(rewardCount: 1, reward: .chest(model: LocalChestModel(id: "", version: 1, displayName: .mock(), closeLocalImagePath: RewardAssetReference(key: "close_gold_chest", source: .appAssets), openLocalImagePath: RewardAssetReference(key: "open_gold_chest", source: .appAssets), textHexColor: nil, backgroundGradientColors: nil)))) { reward in
        print("Reward claimed: \(reward)")
    }
}

#Preview("Cat") {
    ClaimRewardUI(viewModel: ClaimRewardViewModel(chestManager: ChestRepository(assetManager: OfflineAssetManager(), apiService: APIService())), claimReward: LocalRewardModel(rewardCount: 1, reward: .standart(model: LocalQuestRewardModel(id: "1", category: .animal, displayName: .mock(), assetName: "Cat", imageSource: .local, posterImage: RewardAssetReference(key: "Cat", source: .appAssets), remotePath: nil, remoteAssetVersion: nil, textColorHex: nil, textStrokeColorHex: nil, gradientHexes: nil)))) { reward in
        print("Reward claimed: \(reward)")
    }
}
