//
//  OnboardingUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

// MARK: - CONSTANTS

private extension OnboardingUI {
    enum Constants {
        static let waveCenterRatio: CGFloat = 0.15
        static let waveCurrentPoint: CGFloat = 50
        static let handleEdgeInset: CGFloat = 30
        static let nextPagePeekWidth: CGFloat = 15
        static let offscreenWidthRatio: CGFloat = 1.5
        static let advanceThresholdRatio: CGFloat = 0.5
    }
}

struct OnboardingUI: View {

    // MARK: - PROPERTIES

    @GestureState private var isDragging: Bool = false
    @Environment(\.analyticsService) private var analyticsService
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var currentPage = 0
    @State private var fakeIndex = 0
    @State private var models = OnboardingConstants.onboardingModels
    @State private var isPulseAnimating = false

    private var waveCenterY: CGFloat {
        UIScreen.main.bounds.height * Constants.waveCenterRatio
    }

    // MARK: - VIEW

    var body: some View {
        ZStack {
            backPage.ignoresSafeArea()
            currentPageView.ignoresSafeArea()
        }
        .padding(.vertical, 24)
        .ignoresSafeArea()
        .overlay(
            gesturableDot,
            alignment: .topTrailing
        )
        .safeAreaInset(edge: .bottom) { bottomBar }
        .trackScreen(.onboarding)
        .onChange(of: currentPage) { page in
            analyticsService.log(.onboardingStepViewed(stepIndex: page))
        }
        .onAppear {
            var base = OnboardingConstants.onboardingModels
            guard let first = base.first, var last = base.last else { return }
            last.offSet.width = offscreenWidth
            base.append(first)
            base.insert(last, at: 0)
            models = base
            fakeIndex = 1
            currentPage = 0
            isPulseAnimating = true
            analyticsService.log(.tutorialBegin)
        }
    }
}

// MARK: - COMPONENTS

private extension OnboardingUI {
    var backPage: some View {
        Group {
            if models.indices.contains(fakeIndex + 1) {
                BaseOnboardingUI(
                    onboardingModel: models[fakeIndex + 1]
                )
                .zIndex(0)
            } else {
                Color.clear
            }
        }
    }

    var currentPageView: some View {
        Group {
            if models.indices.contains(fakeIndex) {
                let model = models[fakeIndex]
                BaseOnboardingUI(onboardingModel: model)
                    .clipShape(
                        LiquidShape(
                            offset: model.offSet,
                            currentPoint: Constants.waveCurrentPoint,
                            curveCenterY: waveCenterY,
                            layoutDirection: layoutDirection
                        )
                    )
                    .padding(.trailing, Constants.nextPagePeekWidth)
                    .zIndex(1)
            } else {
                Color.clear
            }
        }
    }

    var bottomBar: some View {
        HStack(spacing: 12) {
            let dotCount = max(models.count - 2, 0)
            HStack(spacing: 12) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Colors.selectedButton : Colors.unselectedButton)
                        .frame(width: currentPage == index ? 24 : 16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)
                }
            }
            .a11yGroup(String(format: NSLocalizedString("a11y_page_of", comment: ""), currentPage + 1, dotCount))

            Spacer()
            
            Button {
                if currentPage == dotCount - 1 {
                    openApp()
                } else {
                    nextPage()
                }
            } label: {
                if currentPage == dotCount - 1 {
                    Text("Başla")
                        .foregroundStyle(.white)
                        .scaledFont(size: 24)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(.brown.opacity(0.5))
                        .borderRadius(borderColor: .white)
                } else {
                    Text("Diğer")
                        .foregroundStyle(.white)
                        .scaledFont(size: 24)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(.white.opacity(0.2))
                        .borderRadius(borderColor: .white)
                }
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 36)
    }
    
    var gesturableDot: some View {
        ZStack {
            if !isDragging {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 62, height: 62)
                    .scaleEffect(isPulseAnimating ? 1.25 : 0.9)
                    .opacity(isPulseAnimating ? 0 : 0.45)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isPulseAnimating
                    )
            }
            
            Image(systemName: "circle.fill")
                .font(.callout)
                .frame(width: 50, height: 50)
                .foregroundStyle(.white)
                .scaleEffect(isPulseAnimating && !isDragging ? 1.08 : 0.96)
                .opacity(isDragging ? 0 : 1)
                .animation(
                    isDragging
                    ? .linear(duration: 0.01)
                    : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: isDragging ? false : isPulseAnimating
                )
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .updating($isDragging) { _, out, _ in
                    out = true
                }
                .onChanged { value in
                    if models.indices.contains(fakeIndex) {
                        withAnimation(
                            .interactiveSpring(
                                response: 0.7,
                                dampingFraction: 0.6,
                                blendDuration: 0.6
                            )
                        ) {
                            models[fakeIndex].offSet = logicalTranslation(of: value.translation)
                        }
                    }
                }
                .onEnded { _ in
                    guard models.indices.contains(fakeIndex) else { return }
                    let threshold = getRect().width * Constants.advanceThresholdRatio

                    withAnimation(.spring()) {
                        if -(models[fakeIndex].offSet.width) > threshold {
                            models[fakeIndex].offSet.width = offscreenWidth
                            fakeIndex += 1
                            
                            let realCount = max(models.count - 2, 1)
                            currentPage = (currentPage + 1) % realCount
                            
                            let idx = fakeIndex
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if idx == models.count - 2, models.count > 2 {
                                    for i in 0..<(models.count - 2) {
                                        models[i].offSet = .zero
                                    }
                                    fakeIndex = 0
                                } else if models.indices.contains(idx) {
                                    models[idx].offSet = .zero
                                }
                            }
                        } else {
                            models[fakeIndex].offSet = .zero
                        }
                    }
                }
        )
        .position(x: handleCenterX, y: waveCenterY)
        // `position` resolves its x against the layout direction; pinning it to LTR keeps the
        // handle on the edge `handleCenterX` names, so it can never drift away from the curve.
        .environment(\.layoutDirection, .leftToRight)
        // Purely decorative swipe affordance; the "next" button covers navigation
        .accessibilityHidden(true)
    }
}

// MARK: - HELPERS

private extension OnboardingUI {

    /// Physical x the drag handle sits at: the trailing edge, resolved here rather than left to
    /// `position`, so the handle and the carved curve share one source of truth.
    var handleCenterX: CGFloat {
        layoutDirection == .rightToLeft
        ? Constants.handleEdgeInset
        : UIScreen.main.bounds.width - Constants.handleEdgeInset
    }

    /// Logical width of a page parked off-screen, past the edge it is dragged toward.
    var offscreenWidth: CGFloat {
        -getRect().width * Constants.offscreenWidthRatio
    }

    /// Maps a physical drag onto the logical axis the page math runs on, where a negative width
    /// always means "toward the next page" — leftward in LTR, rightward in RTL.
    func logicalTranslation(of translation: CGSize) -> CGSize {
        CGSize(
            width: layoutDirection == .rightToLeft ? -translation.width : translation.width,
            height: translation.height
        )
    }

    private func nextPage() {
        withAnimation(.spring()) {
            models[fakeIndex].offSet.width = offscreenWidth
            fakeIndex += 1
            
            let realCount = max(models.count - 2, 1)
            currentPage = (currentPage + 1) % realCount
            
            let idx = fakeIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if idx == models.count - 2, models.count > 2 {
                    for i in 0..<(models.count - 2) {
                        models[i].offSet = .zero
                    }
                    fakeIndex = 0
                } else if models.indices.contains(idx) {
                    models[idx].offSet = .zero
                }
            }
        }
    }
    
    private func openApp() {
        analyticsService.log(.tutorialComplete)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    OnboardingUI()
}
