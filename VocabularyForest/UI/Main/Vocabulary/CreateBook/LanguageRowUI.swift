//
//  LanguageRowUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import SwiftUI

struct LanguageRowUI: View {
    
    // MARK: - PROPERTIES
    
    @Binding var isEmpty: Bool
    var language: Language?
    var placeholder: String
    
    // MARK: - VIEW
    
    var body: some View {
        HStack {
            // fixedSize lets the label wrap and grow vertically at accessibility
            // text sizes instead of clipping.
            if let language {
                Text(language.localizedName)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(placeholder)
                    .foregroundStyle(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.gray)
                .a11yDecorative()
        }
        .padding()
        .background(Color.white)
        .borderRadius(borderColor: isEmpty ? .errorBorder : .gray, lineWidth: 1.5)
        .a11yGroup()
    }
}
