//
//  SliderRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

import SwiftUI

func customSliderRow(title: String, icon: String, value: Binding<Double>) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.white)
                .font(.headline)
            Spacer()
            Text("\(Int(value.wrappedValue * 100))%")
                .foregroundStyle(.white.opacity(0.8))
                .font(.caption)
                .monospacedDigit()
        }
        
        Slider(value: value, in: 0...1)
            .tint(Color.brown700)
    }
}
