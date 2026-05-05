//
//  MockCoreData.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.03.2026.
//

@testable import VocabularyForest
@testable import DTO
import Foundation
import CoreData

class MockCoreData: CoreDataManagerProtocol {
    
    // Protokolün zorunlu kıldığı context'ler
    var viewContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    var backgroundContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    // MARK: - 🎭 STUBS (Dublörler - Dışarıdan Veri Enjekte Etmek İçin)
    
    var stubbedBooks: [VocabularyForest.BookModel] = []
    var stubbedSafeBook: VocabularyForest.BookModel?
    // Non-optional olduğu için implicitly unwrapped (!). Testte mutlaka değer atanmalı.
    var stubbedBook: VocabularyForest.Book!
    var stubbedBookHelperModel: VocabularyForest.BookHelperModel?
    
    var stubbedBookcases: [VocabularyForest.BookcaseModel] = []
    var stubbedSafeBookcase: VocabularyForest.BookcaseModel?
    var stubbedBookcaseStatus: VocabularyForest.BookcaseStatus?
    
    var stubbedUpdateBookAnswerResult: VocabularyForest.Resource<Bool>!
    var stubbedImportBookcaseResult: Result<VocabularyForest.Bookcase, VocabularyForest.CoreDataManager.ImportBookcaseError>!

    // MARK: - 🕵️ SPIES (Ajanlar - Kim Neyi Çağırdı Takip Etmek İçin)
    
    var saveCalledCount = 0
    var deleteEverythingCalledCount = 0
    var createBookCalledCount = 0
    var updateBookcaseCalledCount = 0
    var deleteBookcaseCalledCount = 0
    var lastCreatedLearningWord: String?
    var lastImportedRequest: DTO.BookcaseRequest?
    
    // MARK: - ⚙️ CORE METOTLAR
    
    func save(in context: NSManagedObjectContext) {
        saveCalledCount += 1
    }
    
    func save(type contextType: VocabularyForest.CoreDataManager.ContextType) {
        saveCalledCount += 1
    }
    
    func deleteEverything(contextType: VocabularyForest.CoreDataManager.ContextType) {
        deleteEverythingCalledCount += 1
        stubbedBooks.removeAll()
        stubbedBookcases.removeAll()
    }
    
    // MARK: - 📖 BOOK METOTLARI
    
    func updateBookAnswer(book: VocabularyForest.BookModel, type: VocabularyForest.BattleQuestionType, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.Resource<Bool> {
        return stubbedUpdateBookAnswerResult
    }
    
    func createSafeBook(learningWord: String, meaningWord: String, exampleSentence: String?, descriptionWord: String?, partOfSpeech: String?, safeBookcase bookcase: VocabularyForest.BookcaseModel, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.BookModel? {
        createBookCalledCount += 1
        lastCreatedLearningWord = learningWord
        return stubbedSafeBook
    }
    
    func createBook(learningWord: String, meaningWord: String, exampleSentence: String?, descriptionWord: String?, partOfSpeech: String?, in bookcase: VocabularyForest.Bookcase, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.Book {
        createBookCalledCount += 1
        lastCreatedLearningWord = learningWord
        return stubbedBook
    }
    
    func updateBook(bookToUpdate: VocabularyForest.BookModel, learningWord: String, meaningWord: String, descriptionWord: String?, exampleSentence: String?, onComplete: () -> (), contextType: VocabularyForest.CoreDataManager.ContextType) {
        // Senior Dokunuşu: Testin asenkron (beklemede) kalıp donmaması için closure'ı anında tetikliyoruz
        onComplete()
    }
    
    func deleteBook(book: VocabularyForest.BookModel, contextType: VocabularyForest.CoreDataManager.ContextType) {
        stubbedBooks.removeAll { $0 == book }
    }
    
    func fetchBookHelperProperties(book model: VocabularyForest.BookModel, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.BookHelperModel? {
        return stubbedBookHelperModel
    }
    
    func fetchAllSafeBooks(contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    func fetchBooks(model: VocabularyForest.BookcaseModel, sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    func fetchSafeBooks(model: VocabularyForest.BookcaseModel, sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    func fetchBooks(bookcase: VocabularyForest.Bookcase, sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    func fetchAllBooksWithExampleDescription(sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    func fetchSafeBooksExampleDescription(model: VocabularyForest.BookcaseModel, sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    func fetchSafeBooksExampleDescription(bookcase: VocabularyForest.Bookcase, sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookModel]? {
        return stubbedBooks
    }
    
    // MARK: - 📚 BOOKCASE METOTLARI
    
    func updateBookcase(item: VocabularyForest.BookcaseDisplayItem, newName: String, learningLang: VocabularyForest.Language, meaningLang: VocabularyForest.Language, onComplete: () -> (), contextType: VocabularyForest.CoreDataManager.ContextType) {
        updateBookcaseCalledCount += 1
        onComplete()
    }
    
    func createBookcase(name: String, learningLanguage: String, meaningLanguage: String, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.BookcaseModel? {
        return stubbedSafeBookcase
    }
    
    func importBookcase(_ request: DTO.BookcaseRequest, overwrite: Bool, contextType: VocabularyForest.CoreDataManager.ContextType, completion: @escaping (Result<VocabularyForest.Bookcase, VocabularyForest.CoreDataManager.ImportBookcaseError>) -> Void) {
        lastImportedRequest = request // Ajanımız dışarıdan gelen isteği not aldı
        if let result = stubbedImportBookcaseResult {
            completion(result) // Stubbed cevabı anında fırlatıyoruz
        }
    }
    
    func deleteBookcase(bookcase model: VocabularyForest.BookcaseModel, contextType: VocabularyForest.CoreDataManager.ContextType) {
        stubbedBookcases.removeAll { $0 == model }
    }
    
    func deleteBookcase(bookcase: VocabularyForest.Bookcase, contextType: VocabularyForest.CoreDataManager.ContextType) {
            stubbedBookcases.removeAll { $0.id == bookcase.id }
            deleteBookcaseCalledCount += 1
        }
    func fetchBookcaseProperties(bookcase model: VocabularyForest.BookcaseModel, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.BookcaseStatus? {
        return stubbedBookcaseStatus
    }
    
    func fetchSafeBookcases(sortDescriptors: [NSSortDescriptor]?, contextType: VocabularyForest.CoreDataManager.ContextType) -> [VocabularyForest.BookcaseModel]? {
        return stubbedBookcases
    }
    
    func fetchSafeBookcase(book: VocabularyForest.BookModel, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.BookcaseModel? {
        return stubbedSafeBookcase
    }
    
    func fetchBookcase(name: String, learningLanguageCode: String, meaningLanguageCode: String, contextType: VocabularyForest.CoreDataManager.ContextType) -> VocabularyForest.BookcaseModel? {
        return stubbedSafeBookcase
    }
}
