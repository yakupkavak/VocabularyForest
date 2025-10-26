//
//  SelectBookcase.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import SwiftUI
import CoreData

struct SelectBookcaseUI: View {
    
    // MARK: - PROPERTIES
    
    var allBookcases: [Bookcase]
    @Binding var selectedBookcase: BookcaseModel?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredBookcases: [Bookcase] {
        if searchText.isEmpty {
            return allBookcases
        } else {
            return allBookcases.filter {
                $0.unwrappedName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - UI
    
    var body: some View {
        NavigationStack {
            List(filteredBookcases) { bookcase in
                Button(
                    action: {
                        selectedBookcase = BookcaseModel(
                            bookcaseName: bookcase.unwrappedName,
                            createdDate: bookcase.createdDate ?? Date(),
                            learningLanguage: bookcase.unwrappedLearningLanguage,
                            meaningLanguage: bookcase.unwrappedmeaningLanguage,
                            books: []
                        )
                    dismiss()
                }) {
                    BookcaseRow(bookcase: bookcase)
                        .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Select Bookcase")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search Bookcases")
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
