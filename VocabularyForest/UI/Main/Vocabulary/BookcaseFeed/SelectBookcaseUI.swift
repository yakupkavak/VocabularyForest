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
    @State private var editingBookcaseItem: BookcaseDisplayItem?
    @State private var pendingDeleteBookcase: BookcaseModel?

    private var coreDataManager: CoreDataManagerProtocol {
        DC.shared.resolve(type: .singleInstance, for: CoreDataManagerProtocol.self)
    }
    private var analyticsService: AnalyticsServiceProtocol {
        DC.shared.resolve(type: .singleInstance, for: AnalyticsServiceProtocol.self)
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
                            totalBooksCount: bookcase.totalBooksCount,
                            longMemoryCount: bookcase.longMemoryCount,
                            shortMemoryCount: bookcase.shortMemoryCount
                        )
                        setBookcaseDefault(bookcase: bookcase)
                    dismiss()
                }) {
                    BookcaseRow(
                        bookcase: bookcase,
                        animalModel: getRandomAnimalModel(),
                        onEdit: {
                            editingBookcaseItem = BookcaseDisplayItem(
                                id: bookcase.id,
                                bookcase: bookcase,
                                animalModel: getRandomAnimalModel()
                            )
                        },
                        onDelete: {
                            pendingDeleteBookcase = bookcase
                        })
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
            .bookcaseDeleteConfirmation(pendingBookcase: $pendingDeleteBookcase) { bookcase in
                deleteBookcase(bookcase)
            }
            .sheet(item: $editingBookcaseItem) { item in
                BookcaseEditSheet(item: item) { (newName, newLearningLang, newMeaningLang) in
                    coreDataManager.updateBookcase(
                        item: item,
                        newName: newName,
                        learningLang: newLearningLang,
                        meaningLang: newMeaningLang,
                        onComplete: {
                            refreshBookcases()
                            editingBookcaseItem = nil
                        },
                        contextType: .main
                    )
                }
            }
            .sheet(isPresented: $showCreateBookcase) {
                NavigationStack {
                    CreateBookcaseUI(
                        viewModel: CreateBookcaseViewModel(coreDataManager: coreDataManager, analyticsService: analyticsService),
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

    private func deleteBookcase(_ bookcase: BookcaseModel) {
        coreDataManager.deleteBookcase(bookcase: bookcase, contextType: .main)
        // A deleted bookcase must not stay selected in the parent screen
        if selectedBookcase?.id == bookcase.id {
            selectedBookcase = nil
        }
        refreshBookcases()
    }
}
