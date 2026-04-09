//
//  DailySpinUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.04.2026.
//

import SwiftUI
import YKSpinWheel

private extension DailySpinUI {
    private static let models: [SpinModel] = DailySpinRewards.allCases.filter { reward in
        reward != .diamondChest
    }.enumerated().map { index, reward in
        SpinModel(
            id: index + 1,
            text: reward.rewardName,
            image: Image(reward.rewardImage),
            weight: reward.probabilityWeight,
            textColor: reward.rewardColor,
            background: reward.rewardBackground
        )
    }
    private static let backgroundHeight = 0.7
}

struct DailySpinUI: View {
    
    // MARK: - PROPERTIES

    @StateObject private var controller = YKSpinController(models: models)
    @Binding var isVisible: Bool
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let radius = min(screenWidth, screenHeight) / 2
            ZStack {
                Image("krem").resizable().frame(width: screenWidth * 0.96 , height: screenHeight * DailySpinUI.backgroundHeight)
                    .overlay(alignment: .top) {
                        Text("Daily Spin")
                            .offset(y: geometry.size.height * 0.04)
                            .font(
                                .system(size: 22, weight: .heavy, design: .rounded)
                            )
                            .foregroundStyle(
                                .white.opacity(0.95)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 3)
                            
                    }.overlay {
                        VStack {
                            HStack {
                                Spacer()
                                Text("Play everyday and get additional bonuses")
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white.opacity(0.95))
                                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 2)
                                 
                                Spacer()
                            }
                            .overlay(alignment: .bottomTrailing, content: {
                                Button {
                                    isVisible = false
                                } label: {
                                    Image("close_button_gold")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * 0.07)
                                        .foregroundStyle(
                                            goldGradient
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 1)
                                }
                                .offset(x: -geometry.size.width * 0.13, y: -geometry.size.height * 0.01)
                            })
                            .offset(y: geometry.size.height * 0.015)
                            YKSpinWheel(
                                controller: controller,
                                        center: {
                                Image("daliy_spin_center").resizable()
                            },
                                wheelTopPointer: {
                                    Image("çarkıfelek_ok").resizable().scaleEffect(y: -1)
                                }
                            )
                            .ykPieceThinSliceAngleThreshold(60)
                            .ykPointerHeight(radius * 0.2)
                            .ykPointerWidth(radius * 0.2)
                            .ykPointerOffset(-radius * 0.065)
                            .frame(width: screenWidth * 0.68, height: screenHeight * 0.4)
                            .offset(y: geometry.size.height * 0.03)
                            Button{
                                Task {
                                    await controller.startSpin(spinTime: 4, spinTurns: 5)
                                }
                            }label: {
                                Text("Start Spin")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.clickableText.opacity(0.95))
                                .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
                            }.offset(y: geometry.size.height * 0.015)
                        }
                    }
            }
        }
    }
}

enum DailySpinRewards: CaseIterable {
    case goldChest
    case antiqueChest
    case natureChest
    case diamondChest
    case gold
    case water
}

extension DailySpinRewards {
    var rewardCount: Int {
        return switch self {
        case .goldChest:
            1
        case .antiqueChest:
            1
        case .natureChest:
            1
        case .diamondChest:
            1
        case .gold:
            5
        case .water:
            10
        }
    }
    
    var rewardImage: String {
        return switch self {
        case .goldChest:
            ChestBountyModel.gold.rewardImage
        case .antiqueChest:
            ChestBountyModel.antique.rewardImage
        case .natureChest:
            ChestBountyModel.nature.rewardImage
        case .diamondChest:
            ChestBountyModel.diamond.rewardImage
        case .gold:
            QuestRewardModel.gold(count: 4).rewardImage
        case .water:
            QuestRewardModel.water(count: 4).rewardImage
        }
    }
    
    var rewardName: String {
        return switch self {
        case .goldChest:
            ChestBountyModel.gold.rewardName
        case .antiqueChest:
            ChestBountyModel.antique.rewardName
        case .natureChest:
            ChestBountyModel.nature.rewardName
        case .diamondChest:
            ChestBountyModel.diamond.rewardName
        case .gold:
            "Gold \(rewardCount)"
        case .water:
            "Water \(rewardCount)"
        }
    }
    
    var rewardColor: Color {
        return switch self {
        case .goldChest:
            Color(hex: "#F2DA91")
        case .antiqueChest:
            Color(hex: "#F2F2F2")
        case .natureChest:
            Color(hex: "#B6D93B")
        case .diamondChest:
            Color(hex: "#025928")
        case .gold:
            Color(hex: "#D99B29")
        case .water:
            Color(hex: "#598EB2")
        }
    }
    
    var probabilityWeight: Double {
        return switch self {
        case .goldChest:
            3.0
        case .antiqueChest:
            1.0
        case .natureChest:
            1.0
        case .diamondChest:
            1.0
        case .gold:
            5.0
        case .water:
            5.0
        }
    }
    
    // MARK: - Dynamic Gradient Backgrounds
    
    var rewardBackground: AnyView {
        let colors: [Color]

        switch self {
        case .goldChest:
            colors = [
                Color(hex: "#F2DA91"),
                Color(hex: "#027333"),
                Color(hex: "#8C6A3F"),
                Color(hex: "#F2DA91"),
            ]

        case .antiqueChest:
            colors = [
                Color(hex: "#593825"),
                Color(hex: "#BF8C60"),
                Color(hex: "#BFB3A8"),
            ]

        case .natureChest:
            colors = [
                Color(hex: "#EFF299"),
                Color(hex: "#5A7302"),
                Color(hex: "#B6D93B"),
                Color(hex: "#86A614"),
            ]

        case .diamondChest:
            colors = [
                Color(hex: "#EAFAFC"),
                Color(hex: "#C6EFF5"),
                Color(hex: "#90D9E3"),
                Color(hex: "#53B7C6"),
                Color(hex: "#1E687A")
            ]

        case .gold:
            colors = [
                Color(hex: "#FBF1CB"),
                Color(hex: "#E5C77D"),
                Color(hex: "#EEC94B"),
                Color(hex: "#C5963C"),
                Color(hex: "#6C673C")
            ]

        case .water:
            colors = [
                Color(hex: "#E2F5FA"),
                Color(hex: "#9AC0DE"),
                Color(hex: "#77AFCA"),
                Color(hex: "#4D819D"),
                Color(hex: "#24475E")
            ]
        }

        return AnyView(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    DailySpinUI(isVisible: .constant(true))
}
