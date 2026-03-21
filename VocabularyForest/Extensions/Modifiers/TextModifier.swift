//
//  TextModifier.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.03.2026.
//

import SwiftUI

struct OutlinedLargeTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundStyle(.white)
            .fontWeight(.bold)
            .shadow(color: .black, radius: 0.5, x: 1, y: 1)
            .shadow(color: .black, radius: 0.5, x: -1, y: -1)
            .shadow(color: .black, radius: 0.5, x: 1, y: -1)
            .shadow(color: .black, radius: 0.5, x: -1, y: 1)
    }
}

struct OutlinedLineModifier: ViewModifier {
    
    var radius: CGFloat
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: 1, y: 1)
            .shadow(color: color, radius: radius, x: -1, y: -1)
            .shadow(color: color, radius: radius, x: 1, y: -1)
            .shadow(color: color, radius: radius, x: -1, y: 1)
    }
}

extension Text {
    func outlinedLargeTitle() -> some View {
        self.modifier(OutlinedLargeTitleModifier())
    }
    
}

extension View {
    func outlinedLine(radius at: CGFloat, color: Color) -> some View {
        self.modifier(OutlinedLineModifier(radius: at, color: color))
    }
}
