//
//  SelectBookcase.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import SwiftUI
import CoreData
import DependencyContainer

struct SelectBookcaseUI: View {
    
    // MARK: - PROPERTIES
    
    @Binding var selectedBookcase: BookcaseModel?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showCreateBookcase = false
    @State private var bookcases: [BookcaseModel]

    private var coreDataManager: CoreDataManagerProtocol {
        DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
    }

    // MARK: - INIT

    init(allBookcases: [BookcaseModel], selectedBookcase: Binding<BookcaseModel?>) {
        self._selectedBookcase = selectedBookcase
        self._bookcases = State(initialValue: allBookcases)
    }

    var filteredBookcases: [BookcaseModel]  {
        if searchText.isEmpty {
            return bookcases
        } else {
            return bookcases.filter {
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
            .onAppear {
                refreshBookcases()
            }
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
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showCreateBookcase = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateBookcase) {
                NavigationStack {
                    CreateBookcaseUI(
                        viewModel: CreateBookcaseViewModel(coreDataManager: coreDataManager),
                        onCreated: {
                            refreshBookcases()
                            showCreateBookcase = false
                        }
                    )
                }
            }
        }
        .tint(.clickableButton)
    }

    // MARK: - HELPERS

    private func refreshBookcases() {
        bookcases = coreDataManager.fetchSafeBookcases(
            sortDescriptors: nil,
            contextType: .main
        ) ?? []
    }
}
