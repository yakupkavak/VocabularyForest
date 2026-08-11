//
//  BookcaseDetailViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.10.2025.
//

import Combine
import Foundation

final class BookcaseDetailViewModel: ObservableObject {
    
    // MARK: - DEPENDENCIES

    private let dataManager: CoreDataManagerProtocol
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - PROPERTIES
    
    @Published var books: [BookModel] = []
    @Published var searchText = ""
    @Published var createdAnyBook = false
    @Published var editingBook: BookModel? = nil
    private var bookcase: BookcaseModel? = nil
    private var allBooks: [BookModel] = []
    private var cancellables = Set<AnyCancellable>()
    var bookcaseName: String
    var learningLanguage: String
    var meaningLanguage: String
    
    // MARK: - INIT
    
    init(bookcaseName: String, learningLanguage: String, meaningLanguage: String, dataManager: CoreDataManagerProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.bookcaseName = bookcaseName
        self.learningLanguage = learningLanguage
        self.meaningLanguage = meaningLanguage
        self.dataManager = dataManager
        self.analyticsService = analyticsService
        fetchBookcase(bookcaseName: bookcaseName, learningLanguage: learningLanguage, meaningLanguage: meaningLanguage)
        if let bookcase {
            fetchBooks(bookcase: bookcase)
            analyticsService.log(.bookcaseSelected(bookcaseID: bookcase.id.uuidString))
        }
        setListener()
    }
    
    // MARK: - PRIVATE HELPERS
    
    private func setListener(){
        $searchText
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] (newSearchText) in
            guard let self else { return }
            filterBooks(searchText: newSearchText)
        }
        .store(in: &cancellables)
    }
    
    private func filterBooks(searchText: String) {
        if searchText.isEmpty {
            self.books = self.allBooks
            return
        }
        let lowercasedText = searchText.lowercased()
        self.books = self.allBooks.filter { (book: BookModel) -> Bool in
            return book.learningWord.lowercased().contains(lowercasedText) ||
                   book.meaningWord.lowercased().contains(lowercasedText) ||
                   (book.descriptionWord ?? "").lowercased().contains(lowercasedText) ||
                   (book.exampleSentence ?? "").lowercased().contains(lowercasedText)
        }
    }
    
    private func fetchBookcase(bookcaseName: String, learningLanguage: String, meaningLanguage: String){
        bookcase = dataManager.fetchBookcase(
            name: bookcaseName,
            learningLanguageCode: learningLanguage,
            meaningLanguageCode: meaningLanguage,
            contextType: .main
        )
    }
    
    // MARK: - HELPERS

    func deleteBook(at offsets: IndexSet) {
        let booksToDelete = offsets.map { self.books[$0] }
        for book in booksToDelete {
            dataManager.deleteBook(book: book, contextType: .main)
            logBookDeleted()
            if let index = allBooks.firstIndex(of: book) {
                allBooks.remove(at: index)
            }
        }
        if allBooks.isEmpty{
            createdAnyBook = false
        }
        filterBooks(searchText: self.searchText)
    }
    func deleteBookModel(at book: BookModel) {
        dataManager.deleteBook(book: book, contextType: .main)
        logBookDeleted()
        if let index = allBooks.firstIndex(of: book) {
            allBooks.remove(at: index)
        }
        filterBooks(searchText: self.searchText)
    }
    
    func fetchBooks(bookcase: BookcaseModel){
        Task {
            let fetchedBooks = await Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return [] }
                return await dataManager.fetchSafeBooks(
                    model: bookcase,
                    sortDescriptors: nil,
                    contextType: .background
                ) ?? ([] as [BookModel])
            }.value as [BookModel]?
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard let fetchedBooks else { return }
                books = fetchedBooks
                allBooks = fetchedBooks
                if !books.isEmpty{
                    createdAnyBook = true
                    setListener()
                }
            }
        }
    }
    
    func prepareForEdit(book: BookModel) {
        self.editingBook = book
    }
    func updateBook(
        bookToUpdate: BookModel,
        learningWord: String,
        meaningWord: String,
        descriptionWord: String?,
        exampleSentence: String?
    ) {
        dataManager.updateBook(
            bookToUpdate: bookToUpdate,
            learningWord: learningWord,
            meaningWord: meaningWord,
            descriptionWord: descriptionWord,
            exampleSentence: exampleSentence,
            onComplete: {
                if let bookcase = self.bookcase {
                    fetchBooks(bookcase: bookcase)
                    analyticsService.log(.bookEdited(bookcaseID: bookcase.id.uuidString))
                }
                self.editingBook = nil
            },
            contextType: .main)
    }
}

// MARK: - ANALYTICS HELPERS

private extension BookcaseDetailViewModel {

    func logBookDeleted() {
        guard let bookcase else { return }
        analyticsService.log(.bookDeleted(bookcaseID: bookcase.id.uuidString))
    }
}
