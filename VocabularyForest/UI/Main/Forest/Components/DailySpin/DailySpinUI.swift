//
//  DailySpinUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.04.2026.
//

import SwiftUI
import YKSpinWheel
import Combine

// MARK: - CONSTANTS & MODELS

private extension DailySpinUI {
    static let models: [SpinModel] = AdventureReward.allCases.filter { reward in
        reward != .diamondChest
    }.enumerated().map { index, reward in
        SpinModel(
            id: index + 1,
            text: reward.name,
            image: Image(reward.image),
            weight: reward.probabilityWeight,
            textColor: reward.textColor,
            background: reward.gradientBackground
        )
    }
    static let backgroundHeight = 0.7
}

// MARK: - UI

struct DailySpinUI: View {
    
    // MARK: - PROPERTIES

    @StateObject var controller = YKSpinController(models: DailySpinUI.models)
    @Binding var isVisible: Bool
    @Binding var nextSpinTime: Date?
    
    var onRewardClaimed: (SpinModel) -> Void
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                mainCard(size: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - UI COMPONENTS

private extension DailySpinUI {
    
    func mainCard(size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Image("krem")
                .resizable()
                .frame(width: size.width * 0.96, height: size.height * DailySpinUI.backgroundHeight)
            
            VStack(spacing: 0) {
                titleView
                    .padding(.top, size.height * 0.04)
                
                headerSection(size: size)
                    .padding(.top, size.height * 0.015)
                
                spinWheelSection(size: size)
                    .padding(.top, size.height * 0.03)
                
                actionSection
                    .padding(.top, size.height * 0.03)
            }
        }
    }
    
    var titleView: some View {
        Text("Daily Spin")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 3)
    }
    
    func headerSection(size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            HStack {
                Spacer()
                Text("Play everyday and get additional bonuses")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 2)
                Spacer()
            }.offset(y: size.height * 0.01)
            
            Button {
                isVisible = false
            } label: {
                Image("close_button_gold")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width * 0.07)
                    .foregroundStyle(goldGradient)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            .offset(x: -size.width * 0.13, y: size.height * 0.01)
        }
        .frame(width: size.width * 0.96)
    }
    
    func spinWheelSection(size: CGSize) -> some View {
        let radius = min(size.width, size.height) / 2
        
        return YKSpinWheel(
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
        .frame(width: size.width * 0.68, height: size.height * 0.4)
    }
    
    var actionSection: some View {
        Group {
            if let nextSpinTime {
                Text("Wait until \n \(String(describing: nextSpinTime.toFriendlyRemaintime()))")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange.opacity(0.95))
                    .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
            } else {
                Button {
                    Task {
                        if let rewardModel = await controller.startSpin(spinTime: 4, spinTurns: 5) {
                            onRewardClaimed(rewardModel)
                        }
                    }
                } label: {
                    Text("Start Spin")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.title.opacity(0.95))
                        .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - PREVIEW

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
