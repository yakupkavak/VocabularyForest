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
    @State private var searchText = ""
    private var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return LanguageData.allLanguages
        } else {
            return LanguageData.allLanguages.filter {
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
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search for a language")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
