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
}
