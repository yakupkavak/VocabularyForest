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
        static let strokeOpacity: Double = 0.55
        static let shadowOpacity: Double = 0.3
        static let shadowRadius: CGFloat = 1
    }
}

// MARK: - VIEW

/// Small capsule badge showing a reward's economy tier (C/B/A/S/S+).
/// The letter is intentionally not localized; tiers read the same in every language.
struct TierBadgeView: View {

    let tier: RewardTier
    let fontSize: CGFloat

    var body: some View {
        Text(tier.rawValue)
            .scaledFont(size: fontSize, weight: .black, design: .rounded)
            .foregroundStyle(.white)
            .padding(.horizontal, fontSize * Constants.horizontalPaddingRatio)
            .padding(.vertical, fontSize * Constants.verticalPaddingRatio)
            .background(tier.badgeColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(Constants.strokeOpacity), lineWidth: 1)
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
