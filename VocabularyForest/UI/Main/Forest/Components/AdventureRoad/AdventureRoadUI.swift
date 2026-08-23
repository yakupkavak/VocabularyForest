//
//  AdventureRoadUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.04.2026.
//

import SwiftUI

// MARK: - REWARD PALETTE

/// Derives the missing palette stops from the remote colors.
/// Hex parsing itself is not repeated here — it stays in the shared `Color(hex:)` initializer.
private enum AdventureColorMath {

    /// Mixes the color toward white and/or black, both ratios in 0...1
    static func mixed(_ color: Color, whiteMix: Double = 0, blackMix: Double = 0) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ value: CGFloat) -> Double {
            let mixed = (Double(value) + (1 - Double(value)) * whiteMix) * (1 - blackMix)
            return min(max(mixed, 0), 1)
        }
        return Color(.sRGB, red: channel(r), green: channel(g), blue: channel(b), opacity: Double(a))
    }
}

/// Resolves every color the road UI needs from the remote-driven reward data.
/// Chests read their own config colors (deriving from the market background gradient when the
/// dedicated fields are missing), so a newly added chest never drops to a generic fallback look.
private struct AdventureRewardPalette {
    let roadColor: Color
    let cardGradientColors: [Color]
    let borderColors: [Color]
    let claimedOverlayColor: Color
    let valueTextColor: Color

    init(reward: LocalRewardModel) {
        switch reward.reward {
        case .standart(let model):
            let defaults = Self.categoryStyle(for: model.category)
            self.init(
                cardHexes: model.cardGradientHexes ?? defaults.cardHexes,
                roadHex: model.roadColorHex ?? defaults.roadHex,
                textHex: model.cardTextColorHex ?? defaults.textHex
            )
        case .chest(let model):
            self.init(
                cardHexes: model.cardGradientHexes ?? model.backgroundGradientColors ?? [],
                roadHex: model.roadColorHex,
                textHex: model.cardTextColorHex
            )
        }
    }

    /// Missing road/text colors are derived from the normalized light → base → dark card stops
    private init(cardHexes: [String], roadHex: String?, textHex: String?) {
        let stops = Self.normalizedCardColors(cardHexes)
        let base = stops[stops.count / 2]
        let dark = stops[stops.count - 1]

        cardGradientColors = stops
        roadColor = roadHex.map { Color(hex: $0) } ?? base

        let textColor = textHex.map { Color(hex: $0) } ?? AdventureColorMath.mixed(dark, blackMix: 0.35)
        valueTextColor = textColor
        claimedOverlayColor = textColor.opacity(0.15)

        borderColors = [
            Color.white.opacity(0.98),
            base.opacity(0.92),
            dark.opacity(0.9)
        ]
    }

    /// The card design needs at least three stops; short remote gradients gain a light top stop
    private static func normalizedCardColors(_ hexes: [String]) -> [Color] {
        switch hexes.count {
        case 0:
            return ["#F2F2F2", "#BFBFBF", "#8F8F8F"].map { Color(hex: $0) }
        case 1:
            let base = Color(hex: hexes[0])
            return [
                AdventureColorMath.mixed(base, whiteMix: 0.75),
                base,
                AdventureColorMath.mixed(base, blackMix: 0.3)
            ]
        case 2:
            let light = Color(hex: hexes[0])
            return [AdventureColorMath.mixed(light, whiteMix: 0.75), light, Color(hex: hexes[1])]
        default:
            return hexes.map { Color(hex: $0) }
        }
    }

    /// Fixed palette for the closed set of standart reward categories,
    /// used only when the remote reward doesn't specify its own colors
    private static func categoryStyle(for category: QuestRewardModel) -> (roadHex: String, cardHexes: [String], textHex: String) {
        switch category {
        case .gold:
            ("#F4C430", ["#FFF5CC", "#F4C430", "#C88A1E"], "#8B5E00")
        case .water:
            ("#77AFCA", ["#E2F5FA", "#77AFCA", "#3A7192"], "#0B4F6C")
        case .diamond:
            ("#7BDDF2", ["#F0FDFF", "#8BE9F7", "#2783D7"], "#0B3A64")
        case .plant:
            ("#7ED957", ["#EFFFDD", "#7ED957", "#1E8449"], "#2F5D1B")
        case .sculpture:
            ("#B983FF", ["#F3E8FF", "#B983FF", "#5B2A86"], "#4A2270")
        case .animal:
            ("#FF9F45", ["#FFEEDB", "#FF9F45", "#E4572E"], "#8A3417")
        }
    }
}

// MARK: - ACCESSIBILITY TEXT

/// Milestone state is otherwise conveyed only through opacity and glow,
/// so VoiceOver needs an explicit spoken equivalent.
private extension AdventureMilestoneModel {

    var a11yStatusText: String {
        switch status {
        case .locked: String(localized: "a11y_status_locked")
        case .ready: String(localized: "a11y_status_ready")
        case .claimed: String(localized: "a11y_status_claimed")
        }
    }

    var a11yLabel: String {
        let rewardName = switch reward.reward {
        case .standart(let model): model.displayName.localized
        case .chest(let model): model.displayName.localized
        }
        return String(format: NSLocalizedString("a11y_milestone_label", comment: ""), rewardName, wordCount)
    }
}

struct AdventureRoadUI: View {
    
    // MARK: - PROPERTIES
    
    let screenModel: AdventureRoadScreenModel
    @Binding var isVisible: Bool
    let onMilestoneTap: (AdventureMilestoneModel) -> Void
    @Environment(\.safeAreaInsets) private var globalSafeArea
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let safeBottomInset = geometry.safeAreaInsets.bottom
            let horizontalPadding = w * 0.04
            let availableWidth = w - (horizontalPadding * 2)
            
            let cardWidth = availableWidth * 0.38 * 0.85
            let centerWidth = (availableWidth * 0.16) + 4
            
            let rowHeight = cardWidth * 0.8
            let rowSpacingForSideColumns = rowHeight * 0.24

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: w * 0.04) {
                    VStack(spacing: w * 0.045) {
                        topHeaderBar(w: w)
                        titleSection(w: w)
                    }
                    HStack {
                        AdventurePassBadge(track: .shortTerm, theme: screenModel.theme)
                            .frame(width: cardWidth, height: rowHeight * 0.7)
                        
                        Spacer(minLength: 0)
                        
                        AdventurePassBadge(track: .longTerm, theme: screenModel.theme)
                            .frame(width: cardWidth, height: rowHeight * 0.7)
                    }

                    HStack(alignment: .top) {
                        AdventureLaneColumn(
                            milestones: screenModel.rows.map(\.leftMilestone),
                            notchSide: .right,
                            cardWidth: cardWidth,
                            rowHeight: rowHeight,
                            rowSpacing: rowSpacingForSideColumns,
                            wordLabelColor: screenModel.theme.wordLabelTextColor,
                            onMilestoneTap: onMilestoneTap
                        )
                        .frame(width: cardWidth)

                        Spacer(minLength: 0)

                        AdventureCenterRoads(
                            rows: screenModel.rows,
                            centerWidth: centerWidth,
                            cardWidth: cardWidth,
                            columnSpacing: 0,
                            rowHeightOfCard: rowHeight,
                            rowSpacingOfCard: rowSpacingForSideColumns
                        )
                        .frame(width: centerWidth)
                        .accessibilityHidden(true)
                        
                        Spacer(minLength: 0)
                        
                        AdventureLaneColumn(
                            milestones: screenModel.rows.map(\.rightMilestone),
                            notchSide: .left,
                            cardWidth: cardWidth,
                            rowHeight: rowHeight,
                            rowSpacing: rowSpacingForSideColumns,
                            wordLabelColor: screenModel.theme.wordLabelTextColor,
                            onMilestoneTap: onMilestoneTap
                        )
                        .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, safeBottomInset + (w * 0.06))
            }
            .padding(.top, globalSafeArea.top > 0 ? globalSafeArea.top : w * 0.04)        .background(backgroundGradient)
            .trackScreen(.adventureRoad)
        }
    }
}

private extension AdventureRoadUI {
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [screenModel.theme.backgroundTopColor, screenModel.theme.backgroundBottomColor],
            startPoint: .top,
            endPoint: .init(x: 0.5, y: 0.9)
        )
    }
    
    func topHeaderBar(w: CGFloat) -> some View {
        HStack {
            Button {
                isVisible = false
            } label: {
                Image(systemName: "xmark")
                    .scaledFont(size: w * 0.06, weight: .regular)
                    .foregroundStyle(Color.black.opacity(0.72))
                    .frame(width: w * 0.14, height: w * 0.14)
                    .background(Color.white.opacity(0.78))
                    .clipShape(Circle())
            }
            .accessibilityLabel(String(localized: "a11y_close"))

            Spacer()

            HStack(spacing: w * 0.015) {
                Image(systemName: "hourglass")
                    .scaledFont(size: w * 0.04, weight: .semibold)
                Text(screenModel.countdownText)
                    .scaledFont(size: w * 0.04, weight: .medium, design: .rounded)
            }
            .foregroundStyle(screenModel.theme.countdownTextColor)
            .padding(.horizontal, w * 0.035)
            .padding(.vertical, w * 0.023)
            .background(screenModel.theme.countdownBackgroundColor)
            .clipShape(Capsule())
            .a11yGroup()
        }
    }
    
    func titleSection(w: CGFloat) -> some View {
        VStack(spacing: w * 0.025) {
            Text(screenModel.title)
                .scaledFont(size: w * 0.1, weight: .heavy, design: .rounded)
                .foregroundStyle(screenModel.theme.titleTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            if !screenModel.subtitle.isEmpty {
                Text(screenModel.subtitle)
                    .scaledFont(size: w * 0.042, weight: .medium, design: .rounded)
                    .foregroundStyle(screenModel.theme.subtitleTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct AdventurePassBadge: View {
    let track: AdventureMemoryTrack
    let theme: AdventureRoadThemeModel

    var body: some View {
        let title = track.title
        let textColor: Color = track == .shortTerm ? theme.shortBadgeTextColor : theme.longBadgeTextColor
        let bgGradient = LinearGradient(
            colors: track == .shortTerm
                ? [theme.shortBadgeTopColor, theme.shortBadgeBottomColor]
                : [theme.longBadgeTopColor, theme.longBadgeBottomColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        GeometryReader { proxy in
            ZStack {
                AdventurePassBadgeShape()
                    .fill(bgGradient)

                AdventurePassBadgeShape()
                    .stroke(Color.white.opacity(0.85), lineWidth: proxy.size.width * 0.015)

                Text(title)
                    .scaledFont(size: proxy.size.width * 0.15, weight: .heavy, design: .rounded)
                    .padding(.horizontal, 2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(textColor)
                    .offset(y: -proxy.size.height * 0.07 )
            }
        }
    }
}

private struct AdventureLaneColumn: View {
    let milestones: [AdventureMilestoneModel]
    let notchSide: AdventureTicketNotchSide
    let cardWidth: CGFloat
    let rowHeight: CGFloat
    let rowSpacing: CGFloat
    let wordLabelColor: Color
    let onMilestoneTap: (AdventureMilestoneModel) -> Void

    var body: some View {
        let maxWordCount = milestones.map(\.wordCount).max() ?? 0
        VStack(spacing: rowSpacing) {
            ForEach(milestones) { milestone in
                VStack(spacing: rowHeight * 0.08) {
                    AdventureRewardCard(
                        milestone: milestone,
                        notchSide: notchSide,
                        cardWidth: cardWidth,
                        isFinalMilestone: milestone.wordCount == maxWordCount
                    )
                        .frame(height: rowHeight * 0.82)
                        .onTapGesture {
                            onMilestoneTap(milestone)
                        }

                    Text(String(localized: "\(milestone.wordCount) words"))
                        .scaledFont(size: max(cardWidth * 0.1, 11), weight: .bold, design: .rounded)
                        .foregroundStyle(wordLabelColor)
                }
                .frame(height: rowHeight)
                .a11yTapButton(
                    milestone.a11yLabel,
                    value: milestone.a11yStatusText,
                    hint: milestone.status == .ready ? String(localized: "a11y_claim_hint") : nil
                )
            }
        }
    }
}

private struct AdventureCenterRoads: View {
    let rows: [AdventureRoadRowModel]
    let centerWidth: CGFloat
    let cardWidth: CGFloat
    let columnSpacing: CGFloat
    let rowHeightOfCard: CGFloat
    let rowSpacingOfCard: CGFloat
    @State private var shortTitleAnimal = getRandomAnimalModel().head
    @State private var longTitleAnimal = getRandomAnimalModel().head
    
    var body: some View {
        let nodeSegmentHeight = rowHeightOfCard + rowSpacingOfCard
        
        let nodeSize = max(1, centerWidth * 0.52)
        let neckRatio: CGFloat = 0.28
        let cardNotchWidth = cardWidth * 0.12
        let targetLeftNodeCenter = cardNotchWidth - columnSpacing
        let laneCenterDistance = centerWidth - (2 * targetLeftNodeCenter)
        let laneSpacing = max(0, laneCenterDistance - nodeSize * 0.9)
        let targetCardCenterY = rowHeightOfCard * 0.41
        let currentNodeCenterY = nodeSegmentHeight * 0.5
        let nodeVerticalOffset = targetCardCenterY - currentNodeCenterY

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: laneSpacing) {
                    ZStack(alignment: .top) {
                        nodeView(
                            milestone: row.leftMilestone,
                            nodeSize: nodeSize,
                            segmentHeight: nodeSegmentHeight,
                            neckRatio: neckRatio,
                            centerOffsetY: nodeVerticalOffset
                        ).overlay(alignment: .top) {
                            if index == 0 {
                                Image(shortTitleAnimal)
                                    .resizable().scaledToFit()
                                    .frame(width: cardWidth * 0.3)
                                    .foregroundStyle(Color.black.opacity(0.78))
                                    .offset(y: nodeVerticalOffset * 1.5)
                            }
                        }
                    }
                    
                    ZStack(alignment: .top) {
                        nodeView(
                            milestone: row.rightMilestone,
                            nodeSize: nodeSize,
                            segmentHeight: nodeSegmentHeight,
                            neckRatio: neckRatio,
                            centerOffsetY: nodeVerticalOffset
                        ).overlay(alignment: .top) {
                            if index == 0 {
                                Image(longTitleAnimal).resizable().scaledToFit()
                                    .frame(width: cardWidth * 0.3)
                                    .foregroundStyle(Color.black.opacity(0.78))
                                    .offset(y: nodeVerticalOffset * 1.5)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func nodeView(
        milestone: AdventureMilestoneModel,
        nodeSize: CGFloat,
        segmentHeight: CGFloat,
        neckRatio: CGFloat,
        centerOffsetY: CGFloat
    ) -> some View {
        let palette = AdventureRewardPalette(reward: milestone.reward)
        let isReached = milestone.status != .locked
        /// Locked road segments stay plain white, only reached ones take the reward color
        let baseColor = isReached
            ? palette.roadColor
            : Color.white.opacity(0.97)

        ZStack {
            AdventureFlowPath(neckRatio: neckRatio)
                .fill(
                    LinearGradient(
                        colors: isReached
                            ? [
                                baseColor.opacity(0.35),
                                baseColor,
                                baseColor.opacity(0.35)
                              ]
                            : [.white, baseColor, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: nodeSize, height: segmentHeight)
        }
        .offset(y: centerOffsetY)
        .frame(width: nodeSize, height: segmentHeight)
    }
}

private struct AdventureRewardCard: View {
    let milestone: AdventureMilestoneModel
    let notchSide: AdventureTicketNotchSide
    let cardWidth: CGFloat
    let isFinalMilestone: Bool

    private var palette: AdventureRewardPalette {
        AdventureRewardPalette(reward: milestone.reward)
    }

    private var isClaimed: Bool {
        milestone.status == .claimed
    }

    private var isReady: Bool {
        milestone.status == .ready
    }

    private var rewardName: String {
        switch milestone.reward.reward {
        case .standart(let model):
            return model.displayName.localized
        case .chest(let model):
            return model.displayName.localized
        }
    }

    private var amountText: String? {
        switch milestone.reward.reward {
        case .standart:
            /// A single reward doesn't need an "x1" label
            return milestone.reward.rewardCount > 1 ? "x\(milestone.reward.rewardCount)" : nil
        case .chest:
            return nil
        }
    }

    var body: some View {
        let cardShape = AdventureRewardCardShape(notchSide: notchSide)
        let contentPadding = max(0, (cardWidth * 0.05) - 4)

        ZStack {
            cardShape
                .fill(cardFillGradient)

            if isClaimed {
                cardShape
                    .fill(claimedOverlayColor)
            }

            VStack(spacing: cardWidth * 0.035) {
                ZStack {
                    RewardImageView(asset: milestone.reward.reward.posterImage)
                        .scaledToFit()
                        .frame(height: cardWidth * 0.36)
                        .opacity(isClaimed ? 0.35 : 1)
                }

                Text(rewardName)
                    .scaledFont(size: cardWidth * 0.105, weight: .bold, design: .rounded)
                    .foregroundStyle(rewardValueColor)
                    .shadow(color: Color.white.opacity(0.65), radius: 1, x: 0, y: 0)
                    .opacity(isClaimed ? 0.6 : 1)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: cardWidth * 0.9)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.7)

                if let amountText {
                    Text(amountText)
                        .scaledFont(size: cardWidth * 0.12, weight: .heavy, design: .rounded)
                        .foregroundStyle(rewardValueColor)
                        .shadow(color: Color.white.opacity(0.65), radius: 1, x: 0, y: 0)
                        .opacity(isClaimed ? 0.55 : 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .padding(contentPadding)
            .padding(.top, 4)

            if isClaimed {
                claimedBadge
            }
        }
        .overlay(
            cardShape
                .stroke(borderGradient, lineWidth: cardWidth * 0.02)
        )
        .shadow(color: Color.white.opacity(isReady ? 0.9 : 0), radius: isReady ? 5 : 0, x: 0, y: 0)
        .opacity(milestone.status == .locked ? 0.72 : 1)
    }

    private var cardFillGradient: LinearGradient {
        let gradientColors = palette.cardGradientColors
        let colors = gradientColors.enumerated().map { index, color in
            switch index {
            case 0:
                color.opacity(0.98)
            case gradientColors.count - 1:
                color.opacity(0.72)
            default:
                color.opacity(0.78)
            }
        }

        /// The final rewards drop the near-white top stop so the card reads as a rich solid color
        let finalColors = isFinalMilestone ? Array(colors.dropFirst()) : colors

        return LinearGradient(
            colors: finalColors,
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: palette.borderColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var claimedOverlayColor: Color {
        palette.claimedOverlayColor
    }

    private var rewardValueColor: Color {
        /// The final milestone always shines in gold no matter what the reward is
        if isFinalMilestone {
            return Color(hex: "#FFB800")
        }
        return palette.valueTextColor
    }

    private var claimedBadge: some View {
        ZStack {
            Image(systemName: "checkmark")
                .scaledFont(size: cardWidth * 0.2, weight: .black)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}
