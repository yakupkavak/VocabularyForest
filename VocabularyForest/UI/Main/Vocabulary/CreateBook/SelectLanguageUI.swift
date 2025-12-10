//
//  SelectLanguageUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import Foundation
import SwiftUI

struct SelectLanguageUI: View {
    
    // MARK: - PROPERTIES
    
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLanguage: Language?
    @Binding var dismissLanguage: Language?
    @State private var searchText = ""
    private var filteredLanguages: [Language] {
        
        var languages = LanguageData.allLanguages
        if let dismissLanguage {
            languages = languages.filter{ $0.id != dismissLanguage.id }
        }
        
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter {
                $0.localizedName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - VIEWS

    var body: some View {
        NavigationStack {
            List(filteredLanguages) { language in
                Button(action: {
                    selectedLanguage = language
                    dismiss()
                }) {
                    Text(language.localizedName)
                        .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Dil seç")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Hangi dili arıyorsun")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}
