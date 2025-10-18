//
//  OnboardingUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

struct OnboardingUI: View {
    
    // MARK: PROPERTIES
    
    @GestureState private var isDragging: Bool = false
    @State private var currentPage = 0
    @State private var fakeIndex = 0
    @State private var models = OnboardingConstants.onboardingModels

    // MARK: VIEW
    
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
        .onAppear {
            var base = OnboardingConstants.onboardingModels
            guard let first = base.first, var last = base.last else { return }
            last.offSet.width = -getRect().width * 1.5
            base.append(first)
            base.insert(last, at: 0)
            models = base
            fakeIndex = 1
            currentPage = 0
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
                            currentPoint: 50
                        )
                    )
                    .padding(.trailing, 15)
                    .zIndex(1)
            } else {
                Color.clear
            }
        }
    }

    var bottomBar: some View {
        HStack(spacing: 12) {
            let dotCount = max(models.count - 2, 0)
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Colors.selectedButton : Colors.unselectedButton)
                    .frame(width: currentPage == index ? 24 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85),
                               value: currentPage)
            }
            Spacer()
            Button {
                if(currentPage == dotCount - 1) {
                    openApp()
                }else {
                    nextPage()
                }
            } label: {
                if(currentPage == dotCount - 1){
                    tvSubtitle(text: "Over").foregroundStyle(.white)
                }else {
                    tvSubtitle(text: "Next").foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 12)
    }
    
    var gesturableDot: some View {
        Image(systemName: "circle.fill")
            .font(.callout)
            .frame(width: 50, height: 50)
            .foregroundStyle(.white)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($isDragging) { _, out, _ in out = true }
                    .onChanged { value in
                        if models.indices.contains(fakeIndex) {
                            withAnimation(.interactiveSpring(response: 0.7,
                                                             dampingFraction: 0.6,
                                                             blendDuration: 0.6)) {
                                models[fakeIndex].offSet = value.translation
                            }
                        }
                    }
                    .onEnded { _ in
                        guard models.indices.contains(fakeIndex) else { return }
                        let threshold = getRect().width / 2
                        withAnimation(.spring()) {
                            if -(models[fakeIndex].offSet.width) > threshold {
                                models[fakeIndex].offSet.width = -getRect().width * 1.5
                                fakeIndex += 1

                                let realCount = max(models.count - 2, 1)
                                currentPage = (currentPage + 1) % realCount

                                let idx = fakeIndex
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    if idx == models.count - 2, models.count > 2 {
                                        for i in 0..<(models.count - 2) { models[i].offSet = .zero }
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
            .offset(y: 45)
            .opacity(isDragging ? 0 : 1)
            .animation(.linear, value: isDragging)
    }
}

// MARK: - Functions

private extension OnboardingUI{
    
    private func nextPage() {
        withAnimation(.spring()) {
            models[fakeIndex].offSet.width = -getRect().width * 1.5
            fakeIndex += 1
            
            let realCount = max(models.count - 2, 1)
            currentPage = (currentPage + 1) % realCount
            
            let idx = fakeIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if idx == models.count - 2, models.count > 2 {
                    for i in 0..<(models.count - 2) { models[i].offSet = .zero }
                    fakeIndex = 0
                } else if models.indices.contains(idx) {
                    models[idx].offSet = .zero
                }
            }
        }
    }
    
    private func openApp() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    OnboardingUI()
}
