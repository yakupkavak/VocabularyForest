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
    
    var allBookcases: [BookcaseModel]
    @Binding var selectedBookcase: BookcaseModel?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var filteredBookcases: [BookcaseModel]  {
        if searchText.isEmpty {
            return allBookcases
        } else {
            return allBookcases.filter {
                $0.bookcaseName.localizedCaseInsensitiveContains(searchText)
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
                            id: bookcase.id,
                            bookcaseName: bookcase.bookcaseName,
                            createdDate: bookcase.createdDate,
                            learningLanguage: bookcase.learningLanguage,
                            meaningLanguage: bookcase.meaningLanguage,
                        )
                        setBookcaseDefault(bookcase: bookcase)
                    dismiss()
                }) {
                    BookcaseRow(
                        bookcase: bookcase,
                        animalModel: getRandomAnimalModel(),
                        onEdit: {
                        },
                        onDelete: {})
                        .foregroundStyle(.primary)
                }.listRowSeparator(.hidden).listRowInsets(.init())
            }.background(.backgroundSystem)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .navigationTitle("Kitaplık Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.backgroundSystem, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Kitaplık ara")
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
