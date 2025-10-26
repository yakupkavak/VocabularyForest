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
            if let language {
                Text(language.localizedName)
                    .foregroundStyle(.primary)
            } else {
                Text(placeholder)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEmpty ? .errorBorder : .gray, lineWidth: 1.5)
        }
    }
}
