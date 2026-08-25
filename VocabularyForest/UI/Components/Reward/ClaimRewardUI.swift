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
    @AppStorage(AppStorageNames.isHapticsEnabled.rawValue) private var isHapticsEnabled: Bool = true
    @State private var shakeOffset: CGFloat = 0
    @State private var chestStation: ChestStatus = .close
    @State private var isChestLidOpen = false
    @State private var chestScale: CGFloat = 1.0
    @State private var chestRewardIndex = 0
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
                    actionButton(size: geometry.size).opacity(showClaim && isClaimActionReady ? 1 : 0)
                }
            }.task {
                if case .chest(let model) = claimReward.reward {
                    viewModel.openChest(chestID: model.id)
                }
            }
            .trackScreen(.claimReward)
            .onReceive(timer) { _ in
                triggerShake()
            }
        }
        // Reward artwork and prize text share a fixed card; AX3 (~235%) still exceeds
        // the 200% Larger Text requirement while keeping the layout intact.
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

// MARK: - UI COMPONENTS

private extension ClaimRewardUI {
    func backgroundSection(size: CGSize) -> some View {
        let sparklePalette = currentSparklePalette()
        let sparkleSpread = isPad ? min(size.width * 0.6, 600) : size.width * 0.9

        return ZStack {
            if let tier = displayedCelebrationTier {
                celebrationGlow(tier: tier, size: size)
                    .zIndex(1)
            }
            SparklesView(
                spreadDiameter: sparkleSpread,
                primaryColor: sparklePalette.primary,
                secondaryColor: sparklePalette.secondary
            )
            .opacity(0.95)
            .zIndex(2)
            if displayedCelebrationTier == .sPlus {
                /// A second, wider sparkle layer makes the S+ moment scream
                SparklesView(
                    spreadDiameter: sparkleSpread * 1.4,
                    primaryColor: .white,
                    secondaryColor: .tierSPlus
                )
                .opacity(0.85)
                .zIndex(3)
            }
        }
    }

    /// Full-screen radial burst behind the reward for S/S+ celebration moments.
    func celebrationGlow(tier: RewardTier, size: CGSize) -> some View {
        RadialGradient(
            colors: [tier.badgeColor.opacity(0.6), .clear],
            center: .center,
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.55
        )
        .ignoresSafeArea()
        .transition(.opacity)
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    func mainContentSection(size: CGSize) -> some View {
        switch claimReward.reward {
        case .standart(let model):
            standartRewardView(model: model, size: size)
                .a11yGroup()
                .task {
                    A11yAnnouncer.announce(String(format: NSLocalizedString("a11y_reward_won", comment: ""), model.displayName.localized))
                }
        case .chest(let chestModel):
            chestRewardView(chestModel: chestModel, size: size)
                .onTapGesture {
                    openChest()
                }
                .a11yTapButton(chestStation == .close ? String(localized: "a11y_open_chest") : nil)
        }
    }
    
    func standartRewardView(model: LocalQuestRewardModel, size: CGSize) -> some View {
        let mainImageWidth = isPad ? min(size.width * 0.35, 450) : size.width * 0.4
        let rewardTextSize: CGFloat = isPad ? 40 : 32
        
        return VStack {
            if let tier = model.tier {
                TierBadgeView(tier: tier, fontSize: rewardTextSize * 0.5)
            }
            RewardImageView(asset: model.posterImage)
                .scaledToFit()
                .frame(width: mainImageWidth)
            Text(LocalizedStringKey(model.displayName.localized))
                .scaledFont(size: rewardTextSize, weight: .medium, design: .rounded)
                .foregroundColor(model.textColorHex?.color ?? .white)
                .shadow(color: .black.opacity(0.3), radius: 5)
            rewardCountText(count: claimReward.rewardCount, fontSize: rewardTextSize * 0.75, color: model.textColorHex?.color ?? .white)
        }
        .task {
            triggerCelebrationIfNeeded(tier: model.tier)
        }
    }
    
    @ViewBuilder
    func rewardCountText(count: Int, fontSize: CGFloat, color: Color) -> some View {
        if count > 1 {
            Text("x\(count)")
                .scaledFont(size: fontSize, weight: .bold, design: .rounded)
                .foregroundColor(color)
                .shadow(color: .black.opacity(0.3), radius: 5)
        }
    }
    
    @ViewBuilder
    func chestRewardView(chestModel: LocalChestModel, size: CGSize) -> some View {
        let mainImageWidth = isPad ? min(size.width * 0.35, 450) : size.width * 0.4
        let openedChestWidth = mainImageWidth * 0.6

        VStack(spacing: size.height * 0.03) {
            RewardImageView(asset: isChestLidOpen ? chestModel.openLocalImagePath : chestModel.closeLocalImagePath)
                .scaledToFit()
                .frame(width: chestStation == .open ? openedChestWidth : mainImageWidth)
                .scaleEffect(chestScale)
                .offset(x: chestStation == .open ? 0 : shakeOffset)

            if chestStation == .open, let chestRewards = viewModel.chestRewards {
                if chestRewardIndex < chestRewards.count {
                    let currentReward = chestRewards[chestRewardIndex]
                    chestRewardUI(model: currentReward, size: size)
                        .transition(.scale.combined(with: .opacity))
                        .id(chestRewardIndex)
                } else {
                    chestSummaryView(rewards: chestRewards, size: size)
                        .transition(.opacity)
                }
            }
        }
    }
    
    func chestSummaryView(rewards: [LocalRewardModel], size: CGSize) -> some View {
        let columns = [GridItem(.adaptive(minimum: isPad ? 150 : 100))]
        
        return VStack(spacing: 20) {
            Text(LocalizedStringKey("Kazanılan Ödüller"))
                .scaledFont(size: isPad ? 36 : 24, weight: .bold, design: .rounded)
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(rewards.indices, id: \.self) { index in
                    VStack {
                        RewardImageView(asset: rewards[index].reward.posterImage)
                            .scaledToFit()
                            .frame(height: isPad ? 120 : 80)
                        
                        Text(LocalizedStringKey(rewards[index].reward.displayName.localized))
                            .scaledFont(size: isPad ? 20 : 14, weight: .bold, design: .rounded)
                            .foregroundColor(rewards[index].reward.textColorHex?.color ?? .white)
                        rewardCountText(count: rewards[index].rewardCount, fontSize: isPad ? 18 : 12, color: rewards[index].reward.textColorHex?.color ?? .white)
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
            if let tier = model.reward.tier {
                TierBadgeView(tier: tier, fontSize: rewardTextSize * 0.5)
            }
            RewardImageView(asset: model.reward.posterImage)
                .scaledToFit()
                .frame(width: mainImageWidth)
            Text(LocalizedStringKey(model.reward.displayName.localized))
                .scaledFont(size: rewardTextSize, weight: .medium, design: .rounded)
                .foregroundColor(model.reward.textColorHex?.color ?? .white)
                .shadow(color: .black.opacity(0.3), radius: 5)
            rewardCountText(count: model.rewardCount, fontSize: rewardTextSize * 0.75, color: model.reward.textColorHex?.color ?? .white)
        }
        .onAppear {
            A11yAnnouncer.announce(String(format: NSLocalizedString("a11y_reward_won", comment: ""), model.reward.displayName.localized))
            triggerCelebrationIfNeeded(tier: model.reward.tier)
        }
    }

    func actionButton(size: CGSize) -> some View {
        let buttonMaxWidth = isPad ? CGFloat(400) : .infinity
        
        var buttonTitleKey: LocalizedStringKey = "Claim reward"
        
        if case .chest = claimReward.reward, let chestRewards = viewModel.chestRewards, chestStation == .open {
            if chestRewardIndex < chestRewards.count {
                buttonTitleKey = "Next"
            }
        }
        
        return Button(action: {
            handleClaim()
        }) {
            Text(buttonTitleKey)
                .scaledFont(size: isPad ? 38 : 28, weight: .black, design: .rounded)
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
    
    // Derived instead of stored: the dynamic a11y label on the chest flips the
    // subtree's structural identity when it opens, which re-fires any .task/.onAppear
    // there — a stored flag reset inside such a task kept the button hidden forever.
    var showClaim: Bool {
        if case .chest = claimReward.reward { return chestStation == .open }
        return true
    }

    // An opened chest has nothing to claim until its rewards arrive from the
    // repository; hiding the button meanwhile prevents a dead "Claim reward" tap.
    var isClaimActionReady: Bool {
        guard case .chest = claimReward.reward, chestStation == .open else { return true }
        return viewModel.chestRewards != nil || viewModel.errorMessage != nil
    }

    func openChest() {
        guard chestStation == .close, !isChestLidOpen else { return }

        // Lid pops open with a small bounce before the chest settles at the top
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            isChestLidOpen = true
            chestScale = 1.15
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.25)) {
            chestScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                chestStation = .open
            }
        }
    }
    
    func handleClaim() {
        if case .chest = claimReward.reward {
            guard let chestRewards = viewModel.chestRewards else {
                // Rewards are still loading; closing now would swallow the chest
                // content. Only bail out when the open request actually failed.
                if viewModel.errorMessage != nil {
                    onClaim([])
                }
                return
            }
            if chestRewardIndex < chestRewards.count {
                withAnimation(.spring()) {
                    chestRewardIndex += 1
                }
            } else {
                onClaim(chestRewards)
            }
        } else {
            onClaim([claimReward])
        }
    }
    
    func triggerShake() {
        if case .chest = claimReward.reward, !isChestLidOpen {
            withAnimation(.easeInOut(duration: 0.12).repeatCount(5, autoreverses: true)) {
                shakeOffset = 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                shakeOffset = 0
            }
        }
    }
    
    /// Tier of the reward currently on screen when it deserves a celebration
    /// (S or S+); nil keeps the regular category theme.
    var displayedCelebrationTier: RewardTier? {
        switch claimReward.reward {
        case .standart(let model):
            guard let tier = model.tier, tier.isCelebrated else { return nil }
            return tier
        case .chest:
            guard chestStation == .open,
                  let chestRewards = viewModel.chestRewards,
                  chestRewardIndex < chestRewards.count,
                  let tier = chestRewards[chestRewardIndex].reward.tier,
                  tier.isCelebrated else { return nil }
            return tier
        }
    }

    func triggerCelebrationIfNeeded(tier: RewardTier?) {
        guard let tier, tier.isCelebrated else { return }
        viewModel.playCelebrationSound(tier: tier)
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        if tier == .sPlus {
            /// Double burst separates the S+ moment from a regular S drop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }

    func currentSparklePalette() -> SparklePalette {
        if let tier = displayedCelebrationTier {
            return SparklePalette(
                primary: .white,
                secondary: tier.badgeColor,
                shadow: tier.badgeColor
            )
        }
        return currentRewardTheme().sparklePalette
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
    ClaimRewardUI(
        viewModel: ClaimRewardViewModel(
            chestManager: ChestRepository(assetManager: OfflineAssetManager(), apiService: APIService(), pityService: ChestPityService(counterStore: ChestPityCounterStore(), randomRoller: SystemRandomRoller())),
            audioService: ForestAudioService()
        ),
        claimReward: LocalRewardModel(rewardCount: 1, reward: .chest(model: LocalChestModel(id: "", version: 1, displayName: .mock(), closeLocalImagePath: RewardAssetReference(key: "close_gold_chest", source: .appAssets), openLocalImagePath: RewardAssetReference(key: "open_gold_chest", source: .appAssets), textHexColor: nil, backgroundGradientColors: nil)))
    ) { _ in }
}

#Preview("Cat") {
    ClaimRewardUI(
        viewModel: ClaimRewardViewModel(
            chestManager: ChestRepository(assetManager: OfflineAssetManager(), apiService: APIService(), pityService: ChestPityService(counterStore: ChestPityCounterStore(), randomRoller: SystemRandomRoller())),
            audioService: ForestAudioService()
        ),
        claimReward: LocalRewardModel(
            rewardCount: 1,
            reward: .standart(model: LocalQuestRewardModel(id: "1", category: .animal, displayName: .mock(), assetName: "Cat", imageSource: .local, posterImage: RewardAssetReference(key: "Cat", source: .appAssets), remotePath: nil, remoteAssetVersion: nil, textColorHex: nil, textStrokeColorHex: nil, gradientHexes: nil))
        )
    ) { _ in }
}
