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
    
    var reward: DailyBountyModel
    var onClaim: (QuestRewardModel) -> Void
    @State private var chestStatus: ChestStatus = .close
    @State private var isChestOpened: Bool = false
    @State private var revealedReward: QuestRewardModel? = nil
    @State private var shakeOffset: CGFloat = 0
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let sparklePalette = currentSparklePalette()
            
            let mainImageWidth = isPad ? min(width * 0.35, 450) : width * 0.5
            let revealedImageWidth = isPad ? min(width * 0.25, 300) : width * 0.3
            let sparkleSpread = isPad ? min(width * 0.6, 600) : width * 0.8
            let buttonMaxWidth = isPad ? CGFloat(400) : .infinity
            
            ZStack {
                backgroundGradientForCurrentReward().ignoresSafeArea()
                SparklesView(
                    spreadDiameter: sparkleSpread,
                    primaryColor: sparklePalette.primary,
                    secondaryColor: sparklePalette.secondary
                )
                .opacity(0.95)
                .zIndex(0)
                
                VStack {
                    Spacer()
                    switch reward {
                    case .standart(let model):
                        Image(model.rewardImage).resizable().scaledToFit().frame(width: mainImageWidth)
                        Text(model.rewardName)
                            .font(isPad ? .largeTitle : .title)
                            .fontWeight(.bold)
                            .foregroundColor(model.theme.textColor)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    case .chest(let chestModel):
                        ZStack {
                            Image(chestModel.getChestImage(status: chestStatus))
                                .resizable()
                                .scaledToFit()
                                .frame(width: mainImageWidth)
                                .offset(x: shakeOffset)
                                .offset(y: isChestOpened ? height * 0.15 : 0)
                                .zIndex(1)
                            
                            if isChestOpened, let revealed = revealedReward {
                                VStack {
                                    Image(revealed.rewardImage).resizable().scaledToFit().frame(width: revealedImageWidth)
                                        .frame(maxHeight: height * 0.15)
                                    Text(revealed.rewardName)
                                        .font(isPad ? .largeTitle : .title)
                                        .fontWeight(.bold)
                                        .foregroundColor(revealed.theme.textColor)
                                        .shadow(color: .black.opacity(0.3), radius: 5)
                                }
                                .padding(isPad ? 30 : 16)
                                .padding(.horizontal, isPad ? 20 : 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(LinearGradient(colors: revealed.theme.panelColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 32)
                                                .stroke(revealed.theme.panelStroke.opacity(0.55), lineWidth: 1.5)
                                        )
                                )
                                .borderShape(radius: 32)
                                .offset(y: -height * 0.15)
                                .zIndex(2)
                                .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    Spacer()
                    
                    if rewardIsReadyToClaim() {
                        Button(action: {
                            handleClaim()
                        }) {
                            Text(String(localized: "Claim reward"))
                                .font(.system(size: isPad ? 38 : 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, isPad ? 24 : 20)
                                .frame(maxWidth: buttonMaxWidth)
                                .background(claimButtonGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(claimButtonStrokeColor.opacity(0.4), lineWidth: 1.5)
                                )
                                .shadow(color: claimButtonShadowColor.opacity(0.5), radius: 10, x: 0, y: 10)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, isPad ? 80 : 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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

    func backgroundGradientForCurrentReward() -> RadialGradient {
        switch reward {
        case .standart(let model):
            return standardBackgroundGradient(for: model)
        case .chest:
            return RewardHelper.getBackgroundGradient(reward: reward)
        }
    }

    func standardBackgroundGradient(for model: QuestRewardModel) -> RadialGradient {
        let colors: [Color]
        switch model {
        case .plant:
            colors = [Color(hex: "#F3FFE2"), Color(hex: "#B9E779"), Color(hex: "#5FAE35")]
        case .animal:
            colors = [Color(hex: "#EAF7FF"), Color(hex: "#84CDF8"), Color(hex: "#2E77CC")]
        case .sculpture:
            colors = [Color(hex: "#FFF4E8"), Color(hex: "#E7C39E"), Color(hex: "#BB8A5A")]
        default:
            return RewardHelper.getBackgroundGradient(reward: .standart(model: model))
        }
        return RadialGradient(
            gradient: Gradient(colors: [
                colors[0].opacity(0.9),
                colors[1].opacity(0.78),
                colors[2].opacity(0.68)
            ]),
            center: .center,
            startRadius: 30,
            endRadius: 620
        )
    }

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
    
    func currentClaimReward() -> QuestRewardModel? {
        switch reward {
        case .standart(let model):
            return model
        case .chest:
            return revealedReward
        }
    }
}

#Preview {
    ClaimRewardUI(reward: .chest(model: .diamond)) { reward in
        print("Reward claimed: \(reward)")
    }
}
