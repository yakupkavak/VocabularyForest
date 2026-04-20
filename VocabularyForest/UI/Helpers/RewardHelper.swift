//
//  RewardHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.04.2026.
//

import SwiftUI

struct RewardHelper {
    static func getBackgroundGradient(reward: DailyBountyModel) -> RadialGradient {
        let outerColor: Color
        switch reward {
        case .standart(let model):
            switch model {
            case .gold: outerColor = .orange
            case .water: outerColor = .cyan
            case .diamond: outerColor = .purple
            case .plant: outerColor = .mint
            case .animal: outerColor = .brown
            case .sculpture: outerColor = .gray
            }
        case .chest(let model):
            switch model {
            case .gold: outerColor = .orange
            case .nature: outerColor = .mint
            case .diamond: outerColor = .purple
            case .antique: outerColor = .gray
            }
        }
        return RadialGradient(
            gradient: Gradient(colors: [.white.opacity(0.9), outerColor.opacity(0.6), outerColor.opacity(0.9)]),
            center: .center,
            startRadius: 20,
            endRadius: 350
        )
    }
}
