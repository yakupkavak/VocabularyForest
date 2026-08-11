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
    
    // MARK: - DEPENDENCIES

    private let coreDataManager: CoreDataManagerProtocol
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - PROPERTIES
    
    @Published var bookcases: [BookcaseDisplayItem] = []
    @Published var searchText = ""
    @Published var createdAnyBookcase = false
    @Published var editingBookcaseItem: BookcaseDisplayItem? = nil
    private var allBookcases: [BookcaseDisplayItem] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - INIT
  
    init(coreDataManager: CoreDataManagerProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.coreDataManager = coreDataManager
        self.analyticsService = analyticsService
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
            return bookcase.bookcase.bookcaseName.lowercased().contains(lowercasedText)
        }
    }
    
    func fetchBookcases(){
        let fetchedBookcases = coreDataManager.fetchSafeBookcases(
            sortDescriptors: nil,
            contextType: .main
        ) ?? []
        bookcases = fetchedBookcases.map { bookcase in
            BookcaseDisplayItem(
                id: bookcase.id,
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
        analyticsService.set(.bookcaseCount(bookcases.count))
        analyticsService.set(.wordCount(coreDataManager.countAllBooks(contextType: .main)))
    }
    
    func deleteBookcaseIndex(offsets: IndexSet) {
        let bookcasessToDelete = offsets.map { self.bookcases[$0] }
        for bookcaseDisplayItem in bookcasessToDelete {
            coreDataManager.deleteBookcase(bookcase: bookcaseDisplayItem.bookcase, contextType: .main)
            if let index = allBookcases.firstIndex(of: bookcaseDisplayItem) {
                allBookcases.remove(at: index)
            }
        }
        if allBookcases.isEmpty{
            createdAnyBookcase = false
        }
        filterBookcases(searchText: self.searchText)
    }

    func deleteBookcase(bookcase: BookcaseModel) {
        coreDataManager.deleteBookcase(bookcase: bookcase, contextType: .main)
        allBookcases.removeAll { $0.bookcase.id == bookcase.id }
        if allBookcases.isEmpty {
            createdAnyBookcase = false
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
        coreDataManager.updateBookcase(
            item: item,
            newName: newName,
            learningLang: learningLang,
            meaningLang: meaningLang,
            onComplete: {
                fetchBookcases()
                self.editingBookcaseItem = nil
            },
            contextType: .main)
    }
}
