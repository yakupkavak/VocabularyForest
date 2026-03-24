//
//  CoreDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import Foundation
import CoreData
import DependencyContainer
import DTO

// MARK: - CORE DATA MANAGER ENUMS

extension CoreDataManager {
    enum ContextType {
        case main
        case background
    }
    enum ImportBookcaseError: Error {
        case alreadyExist
        case missingRequiredFields
    }
}

// MARK: - CORE DATA PROTOCOL

protocol CoreDataManagerProtocol: AnyObject {
    
    // MARK: Properties
    
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get set }
    
    // MARK: Core Data Operations
    
    func save(in context: NSManagedObjectContext)
    func save(type contextType: CoreDataManager.ContextType)
    func deleteEverything(contextType: CoreDataManager.ContextType)
    
    // MARK: Book Operations
    
    func updateBookAnswer(book: BookModel, type: BattleQuestionType, contextType: CoreDataManager.ContextType) -> Resource<Bool>
    func createSafeBook(learningWord: String, meaningWord: String, exampleSentence: String?, descriptionWord: String?, partOfSpeech: String?, safeBookcase bookcase: BookcaseModel, contextType: CoreDataManager.ContextType) -> BookModel?
    func createBook(learningWord: String, meaningWord: String, exampleSentence: String?, descriptionWord: String?, partOfSpeech: String?, in bookcase: Bookcase, contextType: CoreDataManager.ContextType) -> Book
    func updateBook(bookToUpdate: BookModel, learningWord: String, meaningWord: String, descriptionWord: String?, exampleSentence: String?, onComplete: () -> (), contextType: CoreDataManager.ContextType)
    func deleteBook(book: BookModel, contextType: CoreDataManager.ContextType)
    func fetchBookHelperProperties(book model: BookModel, contextType: CoreDataManager.ContextType) -> BookHelperModel?
    func fetchAllSafeBooks(contextType: CoreDataManager.ContextType) -> [BookModel]?
    func fetchBooks(model: BookcaseModel, sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookModel]?
    func fetchSafeBooks(model: BookcaseModel, sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookModel]?
    func fetchBooks(bookcase: Bookcase, sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookModel]?
    func fetchAllBooksWithExampleDescription(sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookModel]?
    func fetchSafeBooksExampleDescription(model: BookcaseModel, sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookModel]?
    func fetchSafeBooksExampleDescription(bookcase: Bookcase, sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookModel]?
    // MARK: Bookcase Operations
    
    func updateBookcase(item: BookcaseDisplayItem, newName: String, learningLang: Language, meaningLang: Language, onComplete: () -> (), contextType: CoreDataManager.ContextType)
    func createBookcase(name: String, learningLanguage: String, meaningLanguage: String, contextType: CoreDataManager.ContextType) -> BookcaseModel?
    func importBookcase(_ request: BookcaseRequest, overwrite: Bool, contextType: CoreDataManager.ContextType, completion: @escaping (Result<Bookcase, CoreDataManager.ImportBookcaseError>) -> Void)
    func deleteBookcase(bookcase model: BookcaseModel, contextType: CoreDataManager.ContextType)
    func deleteBookcase(bookcase: Bookcase, contextType: CoreDataManager.ContextType)
    func fetchBookcaseProperties(bookcase model: BookcaseModel, contextType: CoreDataManager.ContextType) -> BookcaseStatus?
    func fetchSafeBookcases(sortDescriptors: [NSSortDescriptor]?, contextType: CoreDataManager.ContextType) -> [BookcaseModel]?
    func fetchSafeBookcase(book: BookModel, contextType: CoreDataManager.ContextType) -> BookcaseModel?
    func fetchBookcase(name: String, learningLanguageCode: String, meaningLanguageCode: String, contextType: CoreDataManager.ContextType) -> BookcaseModel?
}

class CoreDataManager: CoreDataManagerProtocol {
    
    // MARK: - PROPERTIES
    
    weak var notificationManager: (any NotificationManagerProtocol)?
    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    
    // MARK: - INIT
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "VocabularyForest")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Core data couldn't inin -> \(error.localizedDescription)")
            }
        }
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.perform { [weak self] in
            guard let self else { return }
            self.checkGame(contextType: .background)
        }
    }
    
    // MARK: - HELPERS
    
    func getContext(for type: ContextType) -> NSManagedObjectContext {
        switch type {
        case .main:
            return viewContext
        case .background:
            return backgroundContext
        }
    }
    
    private func checkGame(contextType: ContextType) {
        let context = getContext(for: contextType)
        context.performAndWait {
            if let allBooks = fetchAllBooks(contextType: contextType) {
                for book in allBooks {
                    if book.longMemory == true {
                        if let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) {
                            if let date = book.learningDate, date <= oneWeekAgo {
                                book.longMemory = false
                                book.shortMemory = true
                            }
                        }
                    }
                }
                save(in: context)
            }
        }
    }
    
    func save(in context: NSManagedObjectContext) {
        context.performAndWait {
            guard context.hasChanges else { return }
            do {
                try context.save()
            } catch {
                print("Core data couldn't saved context \(context) description -> \(error.localizedDescription)")
            }
        }
    }
    
    func save(type contextType: ContextType) {
        let context = getContext(for: contextType)
        context.performAndWait {
            guard context.hasChanges else { return }
            do {
                try context.save()
            } catch {
                print("Core data couldn't saved context \(context) description -> \(error.localizedDescription)")
            }
        }
    }
    
    func deleteEverything(contextType: ContextType) {
        let context = getContext(for: contextType)
        context.performAndWait {
            let entities = CoreDataConstant.entities
            for entity in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try context.execute(deleteRequest)
                } catch {
                    print("Error in \(entity): \(error.localizedDescription)")
                }
            }
            save(in: context)
        }
    }
}

// MARK: - BOOK HELPERS

extension CoreDataManager {
    
    // MARK: - HELPER
    
    func updateBookAnswer(book: BookModel, type: BattleQuestionType, contextType: ContextType) -> Resource<Bool> {
        let context = getContext(for: contextType)
        return context.performAndWait {
            guard let answerBook = fetchSingleBook(book: book, contextType: contextType) else {
                print("updateBookAnswer Error")
                return .error(error: nil)
            }
            if type == .competitive {
                answerBook.shortMemory = false
                answerBook.longMemory = true
                answerBook.learningDate = Date()
                
            }else if type == .remainder {
                answerBook.learningDate = Date()
            }
            save(type: contextType)
            return .success(true)
        }
    }
    
    // MARK: - CREATE HELPERS
    
    func createSafeBook(learningWord: String,
                    meaningWord: String,
                    exampleSentence: String?,
                    descriptionWord: String?,
                    partOfSpeech: String?,
                    safeBookcase bookcase: BookcaseModel,
                    contextType: ContextType) -> BookModel? {
        let context = getContext(for: contextType)
        return context.performAndWait { () -> BookModel? in
            let book = Book(context: context)
            guard let bookcase = fetchSingleBookcase(bookcase: bookcase, contextType: contextType) else { return nil }
            book.learningWord = learningWord
            book.meaningWord = meaningWord
            book.exampleSentence = exampleSentence
            book.descriptionWord = descriptionWord
            book.createdDate = Date()
            book.bookcase = bookcase
            book.partOfSpeech = partOfSpeech
            book.shortMemory = true
            save(in: context)
            let persistentBookID = book.objectID.uriRepresentation().absoluteString
            Task { @MainActor [weak self]in
                self?.notificationManager?.createNotification(
                    bookId: persistentBookID,
                    learningWord: learningWord,
                    meaningWord: meaningWord,
                    description: descriptionWord ?? "",
                    example: exampleSentence ?? ""
                )
            }
            guard let bookId = book.id, let bookcaseId = bookcase.id else { return nil }
            let safeBook = BookModel(id: bookId, bookcaseId: bookcaseId, createdDate: Date(), learningWord: learningWord, meaningWord: meaningWord, longMemory: false, shortMemory: true, partOfSpeech: PartOfSpeech.convertFromCoreData(value: partOfSpeech))
            return safeBook
        }
    }
    
    func createBook(learningWord: String,
                    meaningWord: String,
                    exampleSentence: String?,
                    descriptionWord: String?,
                    partOfSpeech: String?,
                    in bookcase: Bookcase,
                    contextType: ContextType) -> Book {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let book = Book(context: context)
            book.id = UUID()
            book.learningWord = learningWord
            book.meaningWord = meaningWord
            book.exampleSentence = exampleSentence
            book.descriptionWord = descriptionWord
            book.createdDate = Date()
            book.bookcase = bookcase
            book.partOfSpeech = partOfSpeech
            book.shortMemory = true
            save(in: context)
            let persistentBookID = book.objectID.uriRepresentation().absoluteString
            Task { @MainActor [weak self] in
                self?.notificationManager?.createNotification(
                    bookId: persistentBookID,
                    learningWord: learningWord,
                    meaningWord: meaningWord,
                    description: descriptionWord ?? "",
                    example: exampleSentence ?? ""
                )
            }
            return book
        }
    }
    
    // MARK: - UPDATE HELPERS
    
    func updateBook(
        bookToUpdate: BookModel,
        learningWord: String,
        meaningWord: String,
        descriptionWord: String?,
        exampleSentence: String?,
        onComplete: () -> (),
        contextType: ContextType
    ) {
        let context = getContext(for: contextType)
        context.performAndWait {
            guard let book = fetchSingleBook(book: bookToUpdate, contextType: contextType) else { return }
            book.learningWord = learningWord
            book.meaningWord = meaningWord
            book.descriptionWord = (descriptionWord?.isEmpty == false) ? descriptionWord : nil
            book.exampleSentence = (exampleSentence?.isEmpty == false) ? exampleSentence : nil
            save(in: context)
        }
    }
    
    // MARK: - DELETE HELPER
    
    func deleteBook(book: BookModel, contextType: ContextType) {
        let context = getContext(for: contextType)
        context.performAndWait {
            if let bookModel = fetchSingleBook(book: book, contextType: contextType) {
                context.delete(bookModel)
                let persistentBookID = bookModel.objectID.uriRepresentation().absoluteString
                Task { @MainActor [weak self] in
                    self?.notificationManager?.deleteNotification(bookId: persistentBookID)
                }
                save(in: context)
            }
        }
    }
    
    // MARK: - FETCH HELPER
    
    func fetchBookHelperProperties(book model: BookModel, contextType: ContextType) -> BookHelperModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let book = fetchSingleBook(book: model, contextType: contextType)
            if let book, let learningCode = book.bookcase?.learningLanguage, let meaningCode = book.bookcase?.meaningLanguage, let bookcaseName = book.bookcase?.name {
                return BookHelperModel(
                    learningcode: learningCode,
                    meaningCode: meaningCode,
                    bookcaseName: bookcaseName
                )
            }else {
                return nil
            }
        }
    }
    
    func fetchAllSafeBooks(
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            var results: [BookModel]?
            context.performAndWait {
                do {
                    results = try context.fetch(request).map( { try $0.safeObject(context: context) })
                }
                catch {
                    results = nil
                    print("Fetch error: \(error.localizedDescription)")
                }
            }
            return results
        }
    }
    
    func fetchBooks(
        model: BookcaseModel,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            if let bookcase = fetchBookcase(
                name: model.bookcaseName,
                learningLanguageCode: model.learningLanguage,
                meaningLanguageCode: model.meaningLanguage,
                contextType: contextType
            ) {
                let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
                request.sortDescriptors = sortDescriptors ?? [
                    NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
                ]
                if let bookcase = fetchSingleBookcase(bookcase: model, contextType: contextType) {
                    request.predicate = NSPredicate(format: "\(CoreDataConstant.bookcaseEntityName) == %@", bookcase)
                    do {
                        let bookList = try context.fetch(request)
                        let bookModelList = try bookList.map({ try $0.safeObject(context: context) })
                        return bookModelList
                    } catch {
                        print("Books couldn't fetched -> \(error)")
                        return nil
                    }
                }else {
                    return nil
                }
            }else {
                return nil
            }
        }
    }
    
    func fetchSafeBooks(
        model: BookcaseModel,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait { () -> [BookModel]? in
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            guard let bookcase = fetchSingleBookcase(bookcase: model, contextType: contextType) else { return nil }
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(Book.bookcase) ,bookcase)
            do {
                let bookList = try context.fetch(request)
                let bookModelList = try bookList.map({ try $0.safeObject(context: context) })
                return bookModelList
            } catch {
                print("Books couldn't fetched -> \(error)")
                return nil
            }
        }
    }
    
    func fetchBooks(
        bookcase: Bookcase,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            request.predicate = NSPredicate(format: "\(CoreDataConstant.bookcaseEntityName) == %@", bookcase)
            do {
                let bookList = try context.fetch(request)
                let bookModelList = try bookList.map({ try $0.safeObject(context: context) })
                return bookModelList
            } catch {
                print("Books couldn't fetched -> \(error)")
                return nil
            }
        }
    }
    
    func fetchAllBooksWithExampleDescription(
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            request.predicate = NSPredicate(format: "(exampleSentence != nil OR descriptionWord != nil)")
            do {
                let bookList = try context.fetch(request)
                let bookModelList = try bookList.map({ try $0.safeObject(context: context) })
                return bookModelList
            } catch {
                return nil
            }
        }
    }
    
    func fetchSafeBooksExampleDescription(
        model: BookcaseModel,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            if let bookcase = fetchBookcase(
                name: model.bookcaseName,
                learningLanguageCode: model.learningLanguage,
                meaningLanguageCode: model.meaningLanguage,
                contextType: contextType
            ){
                let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
                request.sortDescriptors = sortDescriptors ?? [
                    NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
                ]
                if let bookcase = fetchSingleBookcase(bookcase: model, contextType: contextType) {
                    request.predicate = NSPredicate(format: "\(CoreDataConstant.bookcaseEntityName) == %@ AND (exampleSentence != nil OR descriptionWord != nil)", bookcase)
                    do {
                        let bookList = try context.fetch(request)
                        let bookModelList = try bookList.map({ try $0.safeObject(context: context) })
                        return bookModelList
                    } catch {
                        print("Books couldn't fetched -> \(error)")
                        return nil
                    }
                }else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
    }
    
    func fetchSafeBooksExampleDescription(
        bookcase: Bookcase,
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            request.predicate = NSPredicate(format: "\(CoreDataConstant.bookcaseEntityName) == %@ AND (exampleSentence != nil OR descriptionWord != nil)", bookcase)
            do {
                let bookList = try context.fetch(request)
                let bookModelList = try bookList.map({ try $0.safeObject(context: context) })
                return bookModelList
            } catch {
                print("Books couldn't fetched -> \(error)")
                return nil
            }
        }
    }
}

// MARK: - BOOKCASE HELPERS

extension CoreDataManager {
    
    // MARK: - UPDATE HELPERS
    
    func updateBookcase(
        item: BookcaseDisplayItem,
        newName: String,
        learningLang: Language,
        meaningLang: Language,
        onComplete: () -> (),
        contextType: ContextType
    ) {
        let context = getContext(for: contextType)
        context.performAndWait {
            guard let bookcase = fetchSingleBookcase(bookcase: item.bookcase, contextType: contextType) else { return }
            bookcase.name = newName
            bookcase.learningLanguage = learningLang.id
            bookcase.meaningLanguage = meaningLang.id
            save(in: context)
        }
    }
    
    // MARK: - CREATE HELPERS
    
    func createBookcase(
        name: String,
        learningLanguage: String,
        meaningLanguage: String,
        contextType: ContextType
    ) -> BookcaseModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let bookcase = Bookcase(context: context)
            bookcase.id = UUID()
            bookcase.name = name
            bookcase.learningLanguage = learningLanguage
            bookcase.meaningLanguage = meaningLanguage
            bookcase.createdDate = Date()
            save(in: context)
            return try? bookcase.safeObject(context: context)
        }
    }
    
    func importBookcase(_ request: BookcaseRequest,
                        overwrite: Bool = true,
                        contextType: ContextType,
                        completion: @escaping (Result<Bookcase, ImportBookcaseError>) -> Void) {
        let context = getContext(for: contextType)
        context.performAndWait {
            do {
                guard
                    let source = request.sourceLanguage,
                    let target = request.targetLanguage,
                    let name = request.name
                else { throw ImportBookcaseError.missingRequiredFields }
                
                let bookcaseName = name
                
                let bookcase: Bookcase
                if let existing = self.fetchBookcase(
                    name: bookcaseName,
                    learningLanguageCode: source,
                    meaningLanguageCode: target,
                    contextType: contextType
                ) {
                    completion(.failure(.alreadyExist))
                    return
                } else {
                    bookcase = Bookcase(context: context)
                    bookcase.id = UUID()
                    bookcase.name = bookcaseName
                    bookcase.createdDate = Date()
                }
                bookcase.learningLanguage = source
                bookcase.meaningLanguage = target
                for word in (request.words ?? []) {
                    _ = self.createBook(
                        learningWord: word.term ?? "",
                        meaningWord: word.definition ?? "",
                        exampleSentence: word.example,
                        descriptionWord: word.description,
                        partOfSpeech: word.partOfSpeech,
                        in: bookcase,
                        contextType: contextType
                    )
                }
                
                self.save(in: context)
                completion(.success(bookcase))
                
            } catch {
                completion(.failure(.missingRequiredFields))
            }
        }
    }
    
    // MARK: - DELETE HELPER
    
    func deleteBookcase(bookcase model: BookcaseModel, contextType: ContextType) {
        let context = getContext(for: contextType)
        context.performAndWait {
            let bookcase = fetchSingleBookcase(bookcase: model, contextType: contextType)
            if let bookcase {
                if let books = bookcase.books as? Set<Book> {
                    for book in books {
                        if let bookModel = try? book.safeObject(context: context) {
                            deleteBook(book: bookModel, contextType: contextType)
                        }
                    }
                }
                context.delete(bookcase)
            }
            save(in: context)
        }
    }
    
    func deleteBookcase(bookcase: Bookcase, contextType: ContextType) {
        let context = getContext(for: contextType)
        context.performAndWait {
            if let books = bookcase.books as? Set<Book> {
                for book in books {
                    if let bookModel = try? book.safeObject(context: context) {
                        deleteBook(book: bookModel, contextType: contextType)
                    }
                }
            }
            viewContext.delete(bookcase)
            save(in: context)
        }
    }
    
    // MARK: - FETCH HELPERS
    
    func fetchBookcaseProperties(bookcase model: BookcaseModel, contextType: ContextType) -> BookcaseStatus? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let bookcase = fetchSingleBookcase(bookcase: model, contextType: contextType)
            if let bookcase {
                do {
                    let status = BookcaseStatus(
                        bookList: try bookcase.booksArray.map({ book in
                            try book.safeObject(context: context)
                        }),
                        longMemoryCount: bookcase.longMemoryBooksCount,
                        shortMemoryCount: bookcase.shortMemoryBooksCount,
                        totalBooksCount: bookcase.totalBooksCount,
                        longMemoryBooks: try bookcase.longMemoryBooks.map({ book in
                            try book.safeObject(context: context)
                        }),
                        shortMemoryBooks: try bookcase.shortMemoryBooks.map({ book in
                            try book.safeObject(context: context)
                        })
                    )
                    return status
                }catch {
                    return nil
                }
            }else {
                return nil
            }
        }
    }
    
    func fetchSafeBookcases(
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [BookcaseModel]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Bookcase>(entityName: CoreDataConstant.bookcaseEntityName)
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Bookcase.createdDate, ascending: false)
            ]
            do {
                let list = try context.performAndWait {
                    try context.fetch(request)
                }
                let bookcases = try list.map( { try $0.safeObject(context: context) })
                return bookcases
            } catch {
                return nil
            }
        }
    }
    
    func fetchSafeBookcase(
        book: BookModel,
        contextType: ContextType
    ) -> BookcaseModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Bookcase>(entityName: CoreDataConstant.bookcaseEntityName)
            let bookcaseId = book.bookcaseId
            request.predicate = NSPredicate(format: "id == %@", bookcaseId as CVarArg)
            request.fetchLimit = 1
            do {
                let singleBookcase = try context.performAndWait {
                    try context.fetch(request)
                }
                let safeBookcase = try singleBookcase.first?.safeObject(context: context)
                return safeBookcase
            } catch {
                print("Bookcase coduln't fetched \(error)")
                return nil
            }
        }
    }
    
    func fetchBookcase(
        name: String,
        learningLanguageCode: String,
        meaningLanguageCode: String,
        contextType: ContextType
    ) -> BookcaseModel? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Bookcase>(entityName: CoreDataConstant.bookcaseEntityName)
            request.predicate = NSPredicate(format: "name == %@ AND learningLanguage == %@ AND meaningLanguage == %@", name, learningLanguageCode, meaningLanguageCode)
            request.fetchLimit = 1
            do {
                let bookcases = try context.fetch(request)
                let firtBookcase = bookcases.first
                let bookcase = try firtBookcase?.safeObject(context: context)
                return bookcase
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
    }
}

// MARK: - PRIVATE CORE DATA WORKS

private extension CoreDataManager {
    func fetchSingleBook(book: BookModel, contextType: ContextType) -> Book? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
            request.fetchLimit = 1
            do {
                let booklist = try context.fetch(request)
                return booklist.first
            } catch {
                print("Book id couldn't fetch \(book.id)")
                return nil
            }
        }
    }
    
    func fetchSingleBookcase(bookcase: BookcaseModel, contextType: ContextType) -> Bookcase? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Bookcase>(entityName: CoreDataConstant.bookcaseEntityName)
            request.predicate = NSPredicate(format: "id == %@", bookcase.id as CVarArg)
            request.fetchLimit = 1
            do {
                let booklist = try context.fetch(request)
                return booklist.first
            } catch {
                print("Bookcase id couldn't fetch \(bookcase.id)")
                return nil
            }
        }
    }
    
    func fetchAllBooks(
        sortDescriptors: [NSSortDescriptor]? = nil,
        contextType: ContextType
    ) -> [Book]? {
        let context = getContext(for: contextType)
        return context.performAndWait {
            let request = NSFetchRequest<Book>(entityName: CoreDataConstant.bookEntityName)
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            var results: [Book]?
            context.performAndWait {
                do {
                    results = try context.fetch(request)
                }
                catch {
                    results = nil
                    print("Fetch error: \(error.localizedDescription)")
                }
            }
            return results
        }
    }
}

extension CoreDataManager {
    
    static var preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let context = manager.viewContext
        
        let sampleBookcase = Bookcase(context: context)
        sampleBookcase.name = "Japonca Kelimeler"
        sampleBookcase.createdDate = Date()
        sampleBookcase.learningLanguage = "ja"
        sampleBookcase.meaningLanguage = "tr"
        
        let sampleBook1 = Book(context: context)
        sampleBook1.learningWord = "Konnichiwa"
        sampleBook1.meaningWord = "Merhaba"
        sampleBook1.createdDate = Date().addingTimeInterval(-100)
        sampleBook1.exampleSentence = "Konnichiwa, sensei!"
        sampleBook1.descriptionWord = "Japonca'da 'iyi günler' veya 'merhaba' anlamına gelir."
        sampleBook1.bookcase = sampleBookcase
        
        let sampleBook2 = Book(context: context)
        sampleBook2.learningWord = "Arigatou"
        sampleBook2.meaningWord = "Teşekkürler"
        sampleBook2.createdDate = Date().addingTimeInterval(-200)
        sampleBook2.exampleSentence = "Arigatou gozaimasu."
        sampleBook2.descriptionWord = "Minnettarlık bildiren bir ifade."
        sampleBook2.bookcase = sampleBookcase
        
        let sampleBook3 = Book(context: context)
        sampleBook3.learningWord = "Sayonara"
        sampleBook3.meaningWord = "Güle güle"
        sampleBook3.createdDate = Date().addingTimeInterval(-300)
        sampleBook3.exampleSentence = "Sayonara, mata ashita."
        sampleBook3.descriptionWord = "Ayrılırken kullanılan bir veda sözü."
        sampleBook3.bookcase = sampleBookcase
        
        let sampleBookcase2 = Bookcase(context: context)
        sampleBookcase2.name = "English Basics"
        sampleBookcase2.createdDate = Date().addingTimeInterval(-400)
        sampleBookcase2.learningLanguage = "en"
        sampleBookcase2.meaningLanguage = "tr"
        
        let sampleBook4 = Book(context: context)
        sampleBook4.learningWord = "Apple"
        sampleBook4.meaningWord = "Elma"
        sampleBook4.createdDate = Date().addingTimeInterval(-500)
        sampleBook4.exampleSentence = "An apple a day keeps the doctor away."
        sampleBook4.descriptionWord = "Kırmızı veya yeşil olabilen bir meyve."
        sampleBook4.bookcase = sampleBookcase2
        
        let sampleBook5 = Book(context: context)
        sampleBook5.learningWord = "Code"
        sampleBook5.meaningWord = "Kod"
        sampleBook5.createdDate = Date().addingTimeInterval(-600)
        sampleBook5.exampleSentence = "I need to write some code for my app."
        sampleBook5.descriptionWord = "Bilgisayara talimat vermek için kullanılan komut dizisi."
        sampleBook5.bookcase = sampleBookcase2
        
        let sampleBook6 = Book(context: context)
        sampleBook6.learningWord = "Water"
        sampleBook6.meaningWord = "Su"
        sampleBook6.createdDate = Date().addingTimeInterval(-700)
        sampleBook6.exampleSentence = nil
        sampleBook6.descriptionWord = nil
        sampleBook6.bookcase = sampleBookcase2
        
        manager.save(in: context)
        return manager
    }()
}
