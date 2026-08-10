//
//  SearchBar.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.10.2025.
//


import SwiftUI

struct CustomSearchBar: View {
    
    @Binding var searchText: String
    var placeholder: String = String(localized: "Ara...")
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
                /// Placeholder disappears while typing; keep it as the permanent label
                .accessibilityLabel(placeholder)
                .focused($isFocused)
                .onSubmit { isFocused = false }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "a11y_clear_search"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.gray.withAlphaComponent(0.15)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.selectedBorder : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
    }
}

// MARK: - Preview

#Preview {
    struct ContentView: View {
        @State private var query = ""
        
        var body: some View {
            VStack {
                Text(verbatim: "Query: \(query)")

                CustomSearchBar(searchText: $query, placeholder: String(localized: "Kelime ara"))
                    .padding()
                
                Spacer()
            }
            .background(.backgroundSystem)
        }
    }
    
    return ContentView()
}
