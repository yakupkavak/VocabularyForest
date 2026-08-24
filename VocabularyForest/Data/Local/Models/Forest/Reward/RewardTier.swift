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
}
