//
//  SearchBar.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.10.2025.
//


import SwiftUI

struct CustomSearchBar: View {
    
    @Binding var searchText: String
    var placeholder: String = "Ara..."
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                
            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
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
                Text("Aranan: \(query)")
                
                CustomSearchBar(searchText: $query, placeholder: "Ürün veya hizmet ara...")
                    .padding()
                
                Spacer()
            }
            .background(.backgroundSystem)
        }
    }
    
    return ContentView()
}
