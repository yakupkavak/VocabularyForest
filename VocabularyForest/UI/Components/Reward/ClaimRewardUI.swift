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
    
    var reward: LocalRewardType
    var onClaim: (LocalQuestRewardModel) -> Void
    @State private var chestStatus: ChestStatus = .close
    @State private var isChestOpened: Bool = false
    @State private var revealedReward: LocalQuestRewardModel? = nil
    @State private var shakeOffset: CGFloat = 0
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                //backgroundSection(size: geometry.size)
                
                VStack {
                    Spacer()
                    mainContentSection(size: geometry.size)
                    Spacer()
                    
                    if rewardIsReadyToClaim() {
                        actionButton(size: geometry.size)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }
            .onReceive(timer) { _ in
                triggerShake()
            }
        }
    }
}

// MARK: - UI COMPONENTS

private extension ClaimRewardUI {
    /*
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
     */
    
    @ViewBuilder
    func mainContentSection(size: CGSize) -> some View {
        switch reward {
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
        
        return ZStack {
            RewardImageView(asset: isChestOpened ? chestModel.openLocalImagePath : chestModel.closeLocalImagePath)
                .scaledToFit()
                .frame(width: mainImageWidth)
                .offset(x: shakeOffset)
                .offset(y: isChestOpened ? size.height * 0.15 : 0)
                .zIndex(1)
            
            if isChestOpened, let revealed = revealedReward {
                revealedRewardCard(revealed: revealed, size: size)
            }
        }
    }
    
    func revealedRewardCard(revealed: LocalQuestRewardModel, size: CGSize) -> some View {
        let revealedImageWidth = isPad ? min(size.width * 0.25, 300) : size.width * 0.3
        let rewardTextSize: CGFloat = isPad ? 40 : 32
        
        return VStack {
            RewardImageView(asset: revealed.posterImage)
                .scaledToFit()
                .frame(width: revealedImageWidth)
                .frame(maxHeight: size.height * 0.15)
            Text(LocalizedStringKey(revealed.displayName.localized))
                .font(.system(size: rewardTextSize, weight: .medium, design: .rounded))
                .foregroundColor(revealed.textColorHex?.color)
                .shadow(color: .black.opacity(0.3), radius: 5)
        }
        .padding(isPad ? 30 : 16)
        .padding(.horizontal, isPad ? 20 : 10)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: revealed.gradientHexes?.map{ $0.color } ?? [Color.blue] , startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke((revealed.textStrokeColorHex?.color ?? Color.brown300).opacity(0.55), lineWidth: 1.5)
                )
        )
        .borderShape(radius: 32)
        .offset(y: -size.height * 0.15)
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
                //.background(claimButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                /*.overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(claimButtonStrokeColor.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: claimButtonShadowColor.opacity(0.5), radius: 10, x: 0, y: 10)
                 */
        }
        .padding(.horizontal, 30)
        .padding(.bottom, isPad ? 80 : 50)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - PRIVATE HELPERS

private extension ClaimRewardUI {
    
    func rewardIsReadyToClaim() -> Bool {
        switch reward {
        case .standart:
            return true
        case .chest:
            return isChestOpened
        }
    }
    
    func handleClaim() {
        switch reward {
        case .standart(let model):
            onClaim(model)
        case .chest:
            if let revealed = revealedReward {
                onClaim(revealed)
            }
        }
    }
    
    func handleTap() {
        if case .chest(let chestModel) = reward, !isChestOpened {
            let newReward = RewardHelper.generateRandomReward(from: chestModel)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                chestStatus = .open
                revealedReward = newReward
                isChestOpened = true
            }
        }
    }
    
    func triggerShake() {
        if case .chest = reward, !isChestOpened {
            withAnimation(.easeInOut(duration: 0.12).repeatCount(5, autoreverses: true)) {
                shakeOffset = 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                shakeOffset = 0
            }
        }
    }
   /*
    func currentSparklePalette() -> SparklePalette {
        switch reward {
        case .standart(let model):
            return model.theme.sparklePalette
        case .chest(let chestModel):
            if let revealed = revealedReward {
                return revealed.theme.sparklePalette
            }
            return chestModel.sparklePalette
        }
    }
    
    var claimButtonGradient: LinearGradient {
        let colors = currentClaimReward().map { $0.theme.buttonColors } ?? [Color(hex: "#45D86A"), Color(hex: "#1DAE4A")]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var claimButtonStrokeColor: Color {
        currentClaimReward().map { $0.theme.buttonColors.first ?? $0.theme.panelStroke } ?? Color.white
    }
    
    var claimButtonShadowColor: Color {
        currentClaimReward().map { $0.theme.buttonShadow } ?? Color.black
    }
    */
    func currentClaimReward() -> LocalQuestRewardModel? {
        switch reward {
        case .standart(let model):
            return model
        case .chest:
            return revealedReward
        }
    }
}

// MARK: - PREVIEW

#Preview {/*
    ClaimRewardUI(reward: .chest(model:)) { reward in
        print("Reward claimed: \(reward)")
    }
           */
}
