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
        static var onboardingModels: [OnboardingModel] = [
            OnboardingModel(title: String(localized: "Uzun zamandır sana ihtiyacımız vardı"), animal: "elephant", color: Color.accentColor, backgroundImage: "elephantbackground"),
            OnboardingModel(title: String(localized: "Birlikte öğrenerek ormanımızı baştan yetiştirebiliriz"), animal: "elephant", color: Color.accentColor, backgroundImage: "lionbackground"),
            OnboardingModel(title: String(localized: "Hazırsan başlayalım mı ?"), animal: "elephant", color: Color.accentColor, backgroundImage: "pandabackground"),
        ]
    }
}
