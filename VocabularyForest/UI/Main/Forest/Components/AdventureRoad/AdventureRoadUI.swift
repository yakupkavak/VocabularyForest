//
//  AdventureRoadUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.04.2026.
//

import SwiftUI

struct AdventureRoadUI: View {
    
    private let screenModel = AdventureRoadMockData.screenModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let horizontalPadding = w * 0.04
            let availableWidth = w - (horizontalPadding * 2)
            
            let cardWidth = availableWidth * 0.38 * 0.85
            let centerWidth = (availableWidth * 0.16) + 4
            
            let rowHeight = cardWidth * 0.8
            let rowSpacingForSideColumns = rowHeight * 0.24

            ZStack {
                backgroundGradient

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: w * 0.04) {
                        
                        VStack(spacing: w * 0.045) {
                            topHeaderBar(w: w)
                            titleSection(w: w)
                        }

                        HStack {
                            AdventurePassBadge(track: .shortTerm)
                                .frame(width: cardWidth, height: rowHeight * 0.7)
                            
                            Spacer(minLength: 0)
                            
                            AdventurePassBadge(track: .longTerm)
                                .frame(width: cardWidth, height: rowHeight * 0.7)
                        }

                        HStack(alignment: .top) {
                            AdventureLaneColumn(
                                milestones: screenModel.rows.map(\.leftMilestone),
                                notchSide: .right,
                                cardWidth: cardWidth,
                                rowHeight: rowHeight,
                                rowSpacing: rowSpacingForSideColumns
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
                            
                            Spacer(minLength: 0)
                            
                            AdventureLaneColumn(
                                milestones: screenModel.rows.map(\.rightMilestone),
                                notchSide: .left,
                                cardWidth: cardWidth,
                                rowHeight: rowHeight,
                                rowSpacing: rowSpacingForSideColumns
                            )
                            .frame(width: cardWidth)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, w * 0.02)
                    .padding(.bottom, w * 0.3)
                }
            }
        }
    }
}

private extension AdventureRoadUI {
    
    var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.74, green: 0.88, blue: 0.55), Color(red: 0.16, green: 0.56, blue: 0.33)],
            startPoint: .top,
            endPoint: .init(x: 0.5, y: 0.9)
        )
        .ignoresSafeArea()
    }
    
    func topHeaderBar(w: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: w * 0.06, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .frame(width: w * 0.14, height: w * 0.14)
                    .background(Color.white.opacity(0.78))
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: w * 0.02) {
                Circle()
                    .fill(Color.black.opacity(0.14))
                    .frame(width: w * 0.12, height: w * 0.12)
                    .overlay(
                        Image(systemName: "questionmark.bubble")
                            .font(.system(size: w * 0.055, weight: .medium))
                            .foregroundStyle(.white)
                    )

                HStack(spacing: w * 0.015) {
                    Image(systemName: "hourglass")
                        .font(.system(size: w * 0.04, weight: .semibold))
                    Text(screenModel.countdownText)
                        .font(.system(size: w * 0.04, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, w * 0.035)
                .padding(.vertical, w * 0.023)
                .background(Color.black.opacity(0.14))
                .clipShape(Capsule())
            }
        }
    }
    
    func titleSection(w: CGFloat) -> some View {
        VStack(spacing: w * 0.025) {
            Text(screenModel.title)
                .font(.system(size: w * 0.1, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            Text(String(localized: "adventure_road_subtitle"))
                .font(.system(size: w * 0.042, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
    }
}

private struct AdventurePassBadge: View {
    let track: AdventureMemoryTrack

    var body: some View {
        let title = track.title
        let textColor: Color = track == .shortTerm ? Color(red: 0.04, green: 0.28, blue: 0.33) : .white
        let bgGradient = LinearGradient(
            colors: track == .shortTerm
                ? [Color(red: 0.31, green: 0.87, blue: 0.76).opacity(0.78), Color(red: 0.16, green: 0.74, blue: 0.64).opacity(0.7)]
                : [Color.white.opacity(0.14), Color.white.opacity(0.05)],
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
                    .font(.system(size: proxy.size.width * 0.15, weight: .heavy, design: .rounded))
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

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(milestones) { milestone in
                VStack(spacing: rowHeight * 0.08) {
                    AdventureRewardCard(milestone: milestone, notchSide: notchSide, cardWidth: cardWidth)
                        .frame(height: rowHeight * 0.82)

                    Text(String(localized: "\(milestone.wordCount) words"))
                        .font(.system(size: max(cardWidth * 0.1, 11), weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.96))
                        .shadow(color: Color.white.opacity(0.7), radius: 1, x: 0, y: 0)
                }
                .frame(height: rowHeight)
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
        let baseColor = nodeOuterColor(milestone: milestone)

        ZStack {
            AdventureFlowPath(neckRatio: neckRatio)
                .fill(
                    LinearGradient(
                        colors: [.white, baseColor, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: nodeSize, height: segmentHeight)
            
            if milestone.isClaimed {
                Image(systemName: "checkmark")
                    .font(.system(size: nodeSize * 0.5, weight: .bold))
                    .foregroundStyle(
                        isWhiteNode(milestone: milestone)
                        ? Color.green
                        : Color.white
                    )
            } else {
                EmptyView()
            }
        }
        .offset(y: centerOffsetY)
        .frame(width: nodeSize, height: segmentHeight)
    }

    private func nodeOuterColor(milestone: AdventureMilestoneModel) -> Color {
        switch milestone.reward {
        case .chest(type: .gold):
            return Color(hex: "#E8B83F")
        case .chest(type: .nature):
            return Color(hex: "#99D04E")
        case .chest(type: .diamond):
            return Color(hex: "#7BDDF2")
        case .chest(type: .antique):
            return Color(hex: "#D1A05B")
        default:
            return Color.white.opacity(0.97)
        }
    }

    private func isWhiteNode(milestone: AdventureMilestoneModel) -> Bool {
        switch milestone.reward {
        case .chest:
            return false
        default:
            return true
        }
    }
}

private struct AdventureRewardCard: View {
    let milestone: AdventureMilestoneModel
    let notchSide: AdventureTicketNotchSide
    let cardWidth: CGFloat

    var body: some View {
        let cardShape = AdventureRewardCardShape(notchSide: notchSide)
        let contentPadding = max(0, (cardWidth * 0.05) - 4)

        ZStack {
            cardShape
                .fill(cardFillGradient)

            if milestone.isClaimed {
                cardShape
                    .fill(claimedOverlayColor)
            }

            VStack(spacing: cardWidth * 0.05) {
                ZStack {
                    Image(milestone.reward.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: cardWidth * 0.4)
                        .opacity(milestone.isClaimed ? 0.35 : 1)
                }

                Text(String(localized: String.LocalizationValue(milestone.reward.amountText)))
                    .font(
                        .system(
                            size: milestone.reward.isChestReward ? cardWidth * 0.11 : cardWidth * 0.18,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(rewardValueColor)
                    .opacity(milestone.isClaimed ? (isChestReward ? 0.78 : 0.55) : 1)
                    .multilineTextAlignment(.center)
                    .lineLimit(isChestReward ? 2 : 1)
                    .frame(maxWidth: isChestReward ? cardWidth * 0.52 : cardWidth * 0.9)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(isChestReward ? 1.0 : 0.75)
            }
            .padding(contentPadding)
            .padding(.top, 4)

            if milestone.isClaimed {
                claimedBadge
            }
        }
        .overlay(
            cardShape
                .stroke(borderGradient, lineWidth: cardWidth * 0.02)
        )
    }

    private var cardFillGradient: LinearGradient {
        let colors: [Color]
        switch milestone.reward {
        case .resource(type: .gold, amount: _):
            colors = [
                Color(hex: "#FFF5CC").opacity(0.98),
                Color(hex: "#F4C430").opacity(0.78),
                Color(hex: "#C88A1E").opacity(0.74)
            ]
        case .resource(type: .water, amount: _):
            colors = [
                Color(hex: "#E2F5FA").opacity(0.98),
                Color(hex: "#77AFCA").opacity(0.74),
                Color(hex: "#3A7192").opacity(0.7)
            ]
        case .resource(type: .diamond, amount: _):
            colors = [
                Color(hex: "#F0FDFF").opacity(0.99),
                Color(hex: "#8BE9F7").opacity(0.78),
                Color(hex: "#2783D7").opacity(0.74)
            ]
        case .chest(type: .gold):
            colors = [
                Color(hex: "#FFF1BF").opacity(0.99),
                Color(hex: "#FFCC4D").opacity(0.82),
                Color(hex: "#B67F1E").opacity(0.72)
            ]
        case .chest(type: .nature):
            colors = [
                Color(hex: "#F2FFD5").opacity(0.98),
                Color(hex: "#A8EA6A").opacity(0.78),
                Color(hex: "#4D922A").opacity(0.72)
            ]
        case .chest(type: .diamond):
            colors = [
                Color(hex: "#EAFDFF").opacity(0.99),
                Color(hex: "#72DFFF").opacity(0.82),
                Color(hex: "#2A67D3").opacity(0.72)
            ]
        case .chest(type: .antique):
            colors = [
                Color(hex: "#F7E4C2").opacity(0.99),
                Color(hex: "#CD9F5F").opacity(0.82),
                Color(hex: "#8A5A2B").opacity(0.72)
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        switch milestone.reward {
        case .resource(type: .gold, amount: _), .chest(type: .gold):
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color(hex: "#E8B83F").opacity(0.92),
                    Color(hex: "#B67F1E").opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .resource(type: .water, amount: _):
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.96),
                    Color(hex: "#5FB3D9").opacity(0.9),
                    Color(hex: "#1F6780").opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .resource(type: .diamond, amount: _), .chest(type: .diamond):
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color(hex: "#7BDDF2").opacity(0.92),
                    Color(hex: "#2A67D3").opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .chest(type: .nature):
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color(hex: "#99D04E").opacity(0.92),
                    Color(hex: "#4F8F2D").opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .chest(type: .antique):
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color(hex: "#D1A05B").opacity(0.92),
                    Color(hex: "#8A5A2B").opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var claimedOverlayColor: Color {
        switch milestone.reward {
        case .chest(type: .gold):
            return Color(hex: "#8B5E00").opacity(0.16)
        case .chest(type: .nature):
            return Color(hex: "#2F5D1B").opacity(0.16)
        case .chest(type: .diamond):
            return Color(hex: "#0B3A64").opacity(0.16)
        case .chest(type: .antique):
            return Color(hex: "#6B4A1E").opacity(0.16)
        case .resource(type: .gold, amount: _):
            return Color(hex: "#8B5E00").opacity(0.14)
        case .resource(type: .water, amount: _):
            return Color(hex: "#0B4F6C").opacity(0.14)
        case .resource(type: .diamond, amount: _):
            return Color(hex: "#0B3A64").opacity(0.14)
        }
    }

    private var rewardValueColor: Color {
        switch milestone.reward {
        case .resource(type: .water, amount: _):
            return Color(hex: "#0B4F6C")
        case .resource(type: .gold, amount: _):
            return Color(hex: "#8B5E00")
        case .resource(type: .diamond, amount: _):
            return Color(hex: "#0B3A64")
        case .chest(type: .gold):
            return Color(hex: "#8B5E00")
        case .chest(type: .nature):
            return Color(hex: "#2F5D1B")
        case .chest(type: .diamond):
            return Color(hex: "#0B3A64")
        case .chest(type: .antique):
            return Color(hex: "#6B4A1E")
        }
    }

    private var isChestReward: Bool {
        switch milestone.reward {
        case .chest:
            return true
        default:
            return false
        }
    }

    private var claimedBadge: some View {
        ZStack {
            Image(systemName: "checkmark")
                .font(.system(size: cardWidth * 0.2, weight: .black))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

// MARK: - PREVIEW

#Preview {
    AdventureRoadUI()
}
