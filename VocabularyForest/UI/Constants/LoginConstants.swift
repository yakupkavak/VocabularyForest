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
        private static let centeredTalkingBoxRatio: CGFloat = 0.5
        private static let liftedTalkingBoxRatio: CGFloat = 0.3

        static var onboardingModels: [OnboardingModel] = [
            OnboardingModel(title: String(localized: "Uzun zamandır sana ihtiyacımız vardı"), animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground", talkingBoxCenterRatio: centeredTalkingBoxRatio),
            OnboardingModel(title: String(localized: "Birlikte öğrenerek ormanımızı baştan yetiştirebiliriz"), animal: "elephant", color: Color.accentColor, backgroundImage: "lionbackground", talkingBoxCenterRatio: centeredTalkingBoxRatio),
            OnboardingModel(title: String(localized: "Hazırsan başlayalım mı ?"), animal: "elephant", color: Color.accentColor, backgroundImage: "pandabackground", talkingBoxCenterRatio: liftedTalkingBoxRatio),
        ]
    }
}
