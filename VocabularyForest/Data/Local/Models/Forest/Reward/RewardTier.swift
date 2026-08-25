//
//  RewardTier.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import SwiftUI

/// Economy rarity tier of a reward (C < B < A < S < S+), driven by the
/// `tier` field on remote reward objects. Unknown or missing values stay `nil`
/// so older configs keep working without a badge.
enum RewardTier: String, Hashable, CaseIterable {
    case c = "C"
    case b = "B"
    case a = "A"
    case s = "S"
    case sPlus = "S+"
}

extension RewardTier {
    static func convert(value: String) -> Self? {
        RewardTier(rawValue: value)
    }

    /// S and S+ drops trigger the celebration layer (special sparkles + haptics).
    var isCelebrated: Bool {
        self == .s || self == .sPlus
    }

    /// Base hue of the tier. Also used for tints and glows outside the badge.
    var badgeColor: Color {
        switch self {
        case .c:
            .tierC
        case .b:
            .tierB
        case .a:
            .tierA
        case .s:
            .tierS
        case .sPlus:
            .tierSPlus
        }
    }

    /// Badge fill. C/B/A are flat; S and S+ are two-tone on purpose — gold reads
    /// as currency, and midnight blue rimmed in gold marks the showcase tier.
    var badgeGradient: LinearGradient {
        LinearGradient(
            colors: badgeGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// White drops to 2.6:1 on gold, so S switches to a dark brown letter.
    var badgeTextColor: Color {
        self == .s ? .tierSText : .white
    }

    /// S+ carries a gold rim; the rest keep the soft white hairline.
    var badgeBorderColor: Color {
        self == .sPlus ? .tierSPlusAccent : .white.opacity(Constants.whiteStrokeOpacity)
    }

    /// Sparkles and celebration glow use this instead of `badgeColor`: the S+
    /// badge is deep blue, and blue sparkles vanish on a dark celebration overlay.
    var celebrationColor: Color {
        self == .sPlus ? .tierSPlusAccent : badgeColor
    }

    private var badgeGradientColors: [Color] {
        switch self {
        case .c, .b, .a:
            [badgeColor, badgeColor]
        case .s:
            [.tierSLight, .tierS]
        case .sPlus:
            [.tierSPlus, .tierSPlusLight, .tierSPlus]
        }
    }
}

// MARK: - CONSTANTS

private extension RewardTier {
    enum Constants {
        static let whiteStrokeOpacity: Double = 0.55
    }
}
