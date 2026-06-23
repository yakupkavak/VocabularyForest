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
    
    var claimReward: LocalRewardModel
    var onClaim: (LocalRewardModel) -> Void
    @State private var shakeOffset: CGFloat = 0
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundSection(size: geometry.size)
                
                VStack {
                    Spacer()
                    mainContentSection(size: geometry.size)
                    Spacer()
                    actionButton(size: geometry.size)
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
        let sparkleSpread = isPad ? min(size.width * 0.6, 600) : size.width * 0.8
        
        return ZStack {
            SparklesView(
                spreadDiameter: sparkleSpread,
                primaryColor: sparklePalette.primary,
                secondaryColor: sparklePalette.secondary
            )
            .opacity(0.95)
            .zIndex(0)
        }
    }
    
    @ViewBuilder
    func mainContentSection(size: CGSize) -> some View {
        switch claimReward.reward {
        case .standart(let model):
            standartRewardView(model: model, size: size)
        case .chest(let chestModel):
            chestRewardView(chestModel: chestModel, size: size)
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
    
    func chestRewardView(chestModel: LocalChestModel, size: CGSize) -> some View {
        let mainImageWidth = isPad ? min(size.width * 0.35, 450) : size.width * 0.4
        
        return VStack {
            RewardImageView(asset: chestModel.closeLocalImagePath)
                .scaledToFit()
                .frame(width: mainImageWidth)
                .offset(x: shakeOffset)
            chestRewardCard(model: chestModel, size: size)
        }
    }
    
    func chestRewardCard(model: LocalChestModel, size: CGSize) -> some View {
        let revealedImageWidth = isPad ? min(size.width * 0.25, 300) : size.width * 0.3
        let rewardTextSize: CGFloat = isPad ? 40 : 32
        
        return VStack {
            RewardImageView(asset: model.closeLocalImagePath)
                .scaledToFit()
                .frame(width: revealedImageWidth)
                .frame(maxHeight: size.height * 0.15)
            Text(LocalizedStringKey(model.displayName.localized))
                .font(.system(size: rewardTextSize, weight: .medium, design: .rounded))
                .foregroundColor(model.textHexColor?.color)
                .shadow(color: .black.opacity(0.3), radius: 5)
        }
        .padding(isPad ? 30 : 16)
        .padding(.horizontal, isPad ? 20 : 10)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: model.backgroundGradientColors?.map { $0.color } ?? currentRewardTheme().panelColors, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .borderShape(radius: 32)
        .offset(y: -size.height * 0.05)
        .zIndex(2)
        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
    }
    
    func actionButton(size: CGSize) -> some View {
        let buttonMaxWidth = isPad ? CGFloat(400) : .infinity
        
        return Button(action: {
            handleClaim()
        }) {
            Text(LocalizedStringKey("Claim reward"))
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
    func handleClaim() {
        onClaim(claimReward)
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

#Preview {
    ClaimRewardUI(claimReward: ForestConstant.firstForestRewards[2]) { reward in
        print("Reward claimed: \(reward)")
    }
}
