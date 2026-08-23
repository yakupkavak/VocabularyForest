//
//  ScaledFontModifier.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.08.2026.
//

import SwiftUI

// MARK: - MODIFIER

/// Backs the app's Larger Text (Dynamic Type) support: `Font.system(size:)` alone ignores
/// the user's text size setting, so every fixed-size font is routed through this modifier,
/// which scales the base size with the `.body` text style curve via `@ScaledMetric`.
struct ScaledFontModifier: ViewModifier {

    // MARK: - PROPERTIES

    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    // MARK: - INIT

    init(size: CGFloat, relativeTo textStyle: Font.TextStyle, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

// MARK: - VIEW EXTENSION

extension View {

    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> some View {
        modifier(ScaledFontModifier(size: size, relativeTo: textStyle, weight: weight, design: design))
    }
}
