//
//  BookcaseFeedViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import Combine
import Foundation
internal import CoreData

class BookcaseFeedViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var bookcases: [BookcaseDisplayItem] = []
    @Published var searchText = ""
    @Published var createdAnyBookcase = false
    @Published var editingBookcaseItem: BookcaseDisplayItem? = nil
    private var allBookcases: [BookcaseDisplayItem] = []
    private var cancellables = Set<AnyCancellable>()
    private var manager = CoreDataManager.shared
    
    // MARK: - INIT
    
    init() {
        fetchBookcases()
        setListener()
    }
    
    // MARK: HELPERS
    
    private func setListener() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (newSearchText) in
                guard let self else { return }
                filterBookcases(searchText: newSearchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterBookcases(searchText: String) {
        if searchText.isEmpty {
            self.bookcases = self.allBookcases
            return
        }
        let lowercasedText = searchText.lowercased()
        self.bookcases = self.allBookcases.filter { (bookcase: BookcaseDisplayItem) -> Bool in
            return bookcase.bookcase.unwrappedName.lowercased().contains(lowercasedText)
        }
    }
    
    func fetchBookcases(){
        let fetchedBookcases = manager.fetchBookcases() ?? []
        bookcases = fetchedBookcases.map { bookcase in
            BookcaseDisplayItem(
                id: bookcase.objectID,
                bookcase: bookcase,
                animalModel: getRandomAnimalModel()
            )
        }
        if bookcases.isEmpty {
            allBookcases = []
            createdAnyBookcase = false
        }else {
            allBookcases = bookcases
            createdAnyBookcase = true
        }
    }
    
    func deleteBookcaseIndex(offsets: IndexSet) {
        let bookcasessToDelete = offsets.map { self.bookcases[$0] }
        for bookcaseDisplayItem in bookcasessToDelete {
            manager.deleteBookcase(bookcase: bookcaseDisplayItem.bookcase)
            if let index = allBookcases.firstIndex(of: bookcaseDisplayItem) {
                allBookcases.remove(at: index)
            }
        }
        if allBookcases.isEmpty{
            createdAnyBookcase = false
        }
        filterBookcases(searchText: self.searchText)
    }

    func deleteBookcase(item: BookcaseDisplayItem) {
        manager.deleteBookcase(bookcase: item.bookcase)
        if let index = allBookcases.firstIndex(of: item) {
            allBookcases.remove(at: index)
        }
        filterBookcases(searchText: self.searchText)
    }
    
    func prepareForEdit(item: BookcaseDisplayItem) {
        self.editingBookcaseItem = item
    }

    func updateBookcase(
        item: BookcaseDisplayItem,
        newName: String,
        learningLang: Language,
        meaningLang: Language
    ) {
        let bookcase = item.bookcase
        bookcase.name = newName
        bookcase.learningLanguage = learningLang.id
        bookcase.meaningLanguage = meaningLang.id
        manager.save()
        fetchBookcases()
        self.editingBookcaseItem = nil
    }
}
