//
//  BookcaseDetailViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.10.2025.
//

import Combine
import Foundation

final class BookcaseDetailViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @Published var books: [Book] = []
    @Published var searchText = ""
    @Published var createdAnyBook = false
    @Published var editingBook: Book? = nil
    private var bookcase: Bookcase? = nil
    private var dataManager = CoreDataManager.shared
    private var allBooks: [Book] = []
    private var cancellables = Set<AnyCancellable>()
    var bookcaseName: String
    var learningLanguage: String
    var meaningLanguage: String

    // MARK: - INIT
    
    init(bookcaseName: String, learningLanguage: String, meaningLanguage: String) {
        self.bookcaseName = bookcaseName
        self.learningLanguage = learningLanguage
        self.meaningLanguage = meaningLanguage

        fetchBookcase(bookcaseName: bookcaseName, learningLanguage: learningLanguage, meaningLanguage: meaningLanguage)
        if let bookcase {
            fetchBooks(bookcase: bookcase)
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
        self.books = self.allBooks.filter { (book: Book) -> Bool in
            return book.unwrappedLearningWord.lowercased().contains(lowercasedText) ||
                   book.unwrappedMeaningWord.lowercased().contains(lowercasedText) ||
                   (book.descriptionWord ?? "").lowercased().contains(lowercasedText) ||
                   (book.exampleSentence ?? "").lowercased().contains(lowercasedText)
        }
    }
    private func fetchBookcase(bookcaseName: String, learningLanguage: String, meaningLanguage: String){
        bookcase = dataManager.fetchBookcase(name: bookcaseName, learningLanguageCode: learningLanguage, meaningLanguageCode: meaningLanguage)
    }
    
    // MARK: - HELPERS

    func deleteBook(at offsets: IndexSet) {
        let booksToDelete = offsets.map { self.books[$0] }
        for book in booksToDelete {
            dataManager.deleteBook(book: book)
            if let index = allBooks.firstIndex(of: book) {
                allBooks.remove(at: index)
            }
        }
        if allBooks.isEmpty{
            createdAnyBook = false
        }
        filterBooks(searchText: self.searchText)
    }
    func deleteBookModel(at book: Book) {
        dataManager.deleteBook(book: book)
        if let index = allBooks.firstIndex(of: book) {
            allBooks.remove(at: index)
        }
        filterBooks(searchText: self.searchText)
    }
    func fetchBooks(bookcase: Bookcase){
        books = dataManager.fetchBooks(bookcase: bookcase) ?? []
        allBooks = books
        if !books.isEmpty{
            createdAnyBook = true
            setListener()
        }
    }
    func prepareForEdit(book: Book) {
        self.editingBook = book
    }
    func updateBook(
        bookToUpdate: Book,
        learningWord: String,
        meaningWord: String,
        descriptionWord: String?,
        exampleSentence: String?
    ) {
        bookToUpdate.learningWord = learningWord
        bookToUpdate.meaningWord = meaningWord
        bookToUpdate.descriptionWord = (descriptionWord?.isEmpty == false) ? descriptionWord : nil
        bookToUpdate.exampleSentence = (exampleSentence?.isEmpty == false) ? exampleSentence : nil
        
        dataManager.save()
        if let bookcase = self.bookcase {
            fetchBooks(bookcase: bookcase)
        }
        self.editingBook = nil
    }
}
