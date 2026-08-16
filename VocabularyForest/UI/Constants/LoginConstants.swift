//
//  Onboarding.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import SwiftUI
typealias OnboardingConstants = LoginConstants.OnboardingConstants

struct LoginConstants {
    
    struct OnboardingConstants {
        // Measured from the top, so each page clears its own artwork: 0.5 sits the box halfway up,
        // 0.38 sits it 62% up.
        private static let firstPageTalkingBoxRatio: CGFloat = 0.5
        private static let secondPageTalkingBoxRatio: CGFloat = 0.38
        private static let thirdPageTalkingBoxRatio: CGFloat = 0.45

        static var onboardingModels: [OnboardingModel] = [
            OnboardingModel(title: String(localized: "Burası da neresi"), animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground", talkingBoxCenterRatio: firstPageTalkingBoxRatio),
            OnboardingModel(title: String(localized: "Kendi zihnine hoş geldin. Bizler öğrendiğin kelimelerin yansımalarıyız"), animal: "elephant", color: Color.accentColor, backgroundImage: "lionbackground", talkingBoxCenterRatio: secondPageTalkingBoxRatio),
            OnboardingModel(title: String(localized: "Odaklanıyorum"), animal: "elephant", color: Color.accentColor, backgroundImage: "pandabackground", talkingBoxCenterRatio: thirdPageTalkingBoxRatio),
        ]
    }
}
