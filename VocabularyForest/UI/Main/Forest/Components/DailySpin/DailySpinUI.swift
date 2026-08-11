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
    static let backgroundHeight = 0.7
}

// MARK: - UI

struct DailySpinUI: View {
    
    // MARK: - PROPERTIES

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var controller: YKSpinController
    @Binding var isVisible: Bool
    @Binding var nextSpinTime: Date?
    
    var onRewardClaimed: (SpinModel) -> Void
    
    init(
        models: [SpinModel],
        isVisible: Binding<Bool>,
        nextSpinTime: Binding<Date?>,
        onRewardClaimed: @escaping (SpinModel) -> Void
    ) {
        self._isVisible = isVisible
        self._nextSpinTime = nextSpinTime
        self.onRewardClaimed = onRewardClaimed
        _controller = StateObject(wrappedValue: YKSpinController(models: models))
    }
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                mainCard(size: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .trackScreen(.dailySpin)
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
            .accessibilityLabel(String(localized: "a11y_close"))
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
        .ykPieceVerticalSpacing(4)
        .ykPieceThinSliceAngleThreshold(40)
        .ykPointerHeight(radius * 0.2)
        .ykPointerWidth(radius * 0.2)
        .ykPointerOffset(-radius * 0.065)
        .frame(width: size.width * 0.68, height: size.height * 0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "a11y_spin_wheel"))
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
                        A11yAnnouncer.announce(String(localized: "a11y_spin_started"))
                        // Long decorative spins frustrate VoiceOver and reduce-motion users
                        let quickSpin = reduceMotion || A11yAnnouncer.isVoiceOverOn
                        if let rewardModel = await controller.startSpin(spinTime: quickSpin ? 1 : 4, spinTurns: quickSpin ? 1 : 5) {
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
                .accessibilityHint(String(localized: "a11y_spin_hint"))
            }
        }
    }
}

// MARK: - PREVIEW

#Preview {
    DailySpinPreviewWrapper()
}

struct DailySpinPreviewWrapper: View {
    @State private var models: [SpinModel] = [SpinModel(id: 1, image: Image(systemName: "heart"))]
    @State private var isLoaded = true
    
    var body: some View {
        Group {
            if isLoaded {
                DailySpinUI(
                    models: models,
                    isVisible: .constant(true),
                    nextSpinTime: .constant(nil),
                    onRewardClaimed: { _ in }
                )
            } else {
                ProgressView("Çark Yükleniyor...")
            }
        }
    }
}
