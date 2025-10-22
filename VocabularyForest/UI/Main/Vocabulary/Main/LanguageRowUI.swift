//
//  LanguageRowUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import SwiftUI

struct LanguageRowUI: View {
    var language: Language?
    var placeholder: String
    
    var body: some View {
        HStack {
            if let language {
                Text(language.localizedName)
                    .foregroundStyle(.primary)
            } else {
                Text(placeholder)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        }
    }
}
