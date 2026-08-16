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
        // 0.4 sits it 60% up.
        private static let firstPageTalkingBoxRatio: CGFloat = 0.5
        private static let secondPageTalkingBoxRatio: CGFloat = 0.4
        private static let thirdPageTalkingBoxRatio: CGFloat = 0.45

        static var onboardingModels: [OnboardingModel] = [
            OnboardingModel(title: String(localized: "Uzun zamandır sana ihtiyacımız vardı"), animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground", talkingBoxCenterRatio: firstPageTalkingBoxRatio),
            OnboardingModel(title: String(localized: "Birlikte öğrenerek ormanımızı baştan yetiştirebiliriz"), animal: "elephant", color: Color.accentColor, backgroundImage: "lionbackground", talkingBoxCenterRatio: secondPageTalkingBoxRatio),
            OnboardingModel(title: String(localized: "Hazırsan başlayalım mı ?"), animal: "elephant", color: Color.accentColor, backgroundImage: "pandabackground", talkingBoxCenterRatio: thirdPageTalkingBoxRatio),
        ]
    }
}
