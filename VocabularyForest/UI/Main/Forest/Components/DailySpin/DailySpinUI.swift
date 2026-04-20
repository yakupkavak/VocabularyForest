//
//  DailySpinUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.04.2026.
//

import SwiftUI
import YKSpinWheel
import Combine

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

    @StateObject var controller = YKSpinController(models: models)
    @Binding var isVisible: Bool
    @Binding var nextSpinTime: Date?
    
    var onRewardClaimed: (SpinModel) -> Void
    
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
                            
                            Group {
                                if let nextSpinTime {
                                    Text("Wait until \n \(String(describing: nextSpinTime.toFriendlyRemaintime()))")
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.orange.opacity(0.95))
                                    .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
                                }else {
                                    Button{
                                        Task {
                                            if let rewardModel = await controller.startSpin(spinTime: 4, spinTurns: 5) {
                                                onRewardClaimed(rewardModel)
                                            }
                                        }
                                    }label: {
                                        Text("Start Spin")
                                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.clickableText.opacity(0.95))
                                        .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
                                    }
                                }
                            }
                            .offset(y: geometry.size.height * 0.015)
                        }
                    }
            }
        }
    }
}

#Preview {
    struct DailySpinPreviewWrapper: View {
        @State private var isVisible = true
        @State private var nextSpinTime: Date? = Date().addingTimeInterval(86400)
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        var body: some View {
            DailySpinUI(
                isVisible: $isVisible,
                nextSpinTime: $nextSpinTime
            ) { reward in
                print("Kazanılan Ödül: \(reward)")
            }
            .onReceive(timer) { _ in
                if let currentTime = nextSpinTime {
                    nextSpinTime = currentTime.addingTimeInterval(-1)
                }
            }
        }
    }
    return DailySpinPreviewWrapper()
}
