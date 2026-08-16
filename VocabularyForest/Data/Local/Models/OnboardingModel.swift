//
//  OnboardingModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import SwiftUI

struct OnboardingModel: Identifiable {
    var id = UUID()
    var title: String?
    var headline: String?
    var animal: String?
    var color: Color
    var offSet: CGSize = .zero
    var backgroundImage: String?
    /// Vertical center of the talking box, measured from the top of the screen, so each page can
    /// clear whatever its own artwork puts in the way: 0.5 centers it, 0.3 lifts it 70% of the way up.
    var talkingBoxCenterRatio: CGFloat = 0.5
}
