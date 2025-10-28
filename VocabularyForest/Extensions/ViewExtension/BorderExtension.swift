//
//  BorderExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.10.2025.
//

import SwiftUI

extension View {
    func borderRadius(borderColor: Color, cornerRadius: CGFloat = 16, lineWidth: CGFloat = 1.5) -> some View {
        self.clipShape(
            RoundedRectangle(cornerRadius: cornerRadius)
        ).overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: lineWidth)
        }
    }
}
