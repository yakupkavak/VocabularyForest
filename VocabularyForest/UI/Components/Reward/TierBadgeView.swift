//
//  TierBadgeView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import SwiftUI

// MARK: - CONSTANTS

private extension TierBadgeView {
    enum Constants {
        static let horizontalPaddingRatio: CGFloat = 0.6
        static let verticalPaddingRatio: CGFloat = 0.25
        static let shadowOpacity: Double = 0.3
        static let borderWidth: CGFloat = 1
        static let sPlusBorderWidth: CGFloat = 1.5
        static let shadowRadius: CGFloat = 1
    }
}

// MARK: - VIEW

/// Small capsule badge showing a reward's economy tier (C/B/A/S/S+).
/// The letter is intentionally not localized; tiers read the same in every language.
struct TierBadgeView: View {

    let tier: RewardTier
    let fontSize: CGFloat

    private var borderWidth: CGFloat {
        tier == .sPlus ? Constants.sPlusBorderWidth : Constants.borderWidth
    }

    var body: some View {
        Text(tier.rawValue)
            .scaledFont(size: fontSize, weight: .black, design: .rounded)
            .foregroundStyle(tier.badgeTextColor)
            .padding(.horizontal, fontSize * Constants.horizontalPaddingRatio)
            .padding(.vertical, fontSize * Constants.verticalPaddingRatio)
            .background(tier.badgeGradient)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(tier.badgeBorderColor, lineWidth: borderWidth)
            )
            .shadow(color: .black.opacity(Constants.shadowOpacity), radius: Constants.shadowRadius)
            .accessibilityLabel(String(
                format: NSLocalizedString("a11y_reward_tier", comment: ""),
                tier.rawValue
            ))
    }
}

// MARK: - PREVIEW

#Preview {
    HStack {
        ForEach(RewardTier.allCases, id: \.self) { tier in
            TierBadgeView(tier: tier, fontSize: 14)
        }
    }
    .padding()
    .background(Color.black)
}
