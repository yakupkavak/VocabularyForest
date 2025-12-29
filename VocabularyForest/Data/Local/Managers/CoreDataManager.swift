//
//  CoreDataManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//

import Foundation
import CoreData

class CoreDataManager {
    
    // MARK: - PROPERTIES
    
    static let shared = CoreDataManager()
    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init(inMemory: Bool = false) {
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
        checkGame()
    }
    
    // MARK: - HELPERS
    
    private func checkGame() {
        // Eğer bir hafta geçmişse short memory'e atıyoruz
        if let allBooks = fetchAllBooks() {
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
            save()
        }
    }
    
    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Core data couldn't saved -> \(error.localizedDescription)")
        }
    }
    
    func createBookcase(name: String, learningLanguage: String, meaningLanguage: String) -> Bookcase {
        let bookcase = Bookcase(context: viewContext)
        bookcase.name = name
        bookcase.learningLanguage = learningLanguage
        bookcase.meaningLanguage = meaningLanguage
        bookcase.createdDate = Date()
        save()
        return bookcase
    }
    
    func fetchBookcases(sortDescriptors: [NSSortDescriptor]? = nil) -> [Bookcase]? {
        let request = NSFetchRequest<Bookcase>(entityName: "Bookcase")
        request.sortDescriptors = sortDescriptors ?? [
            NSSortDescriptor(keyPath: \Bookcase.createdDate, ascending: false)
        ]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Bookcases couldn't fetched -> \(error)")
            return nil
        }
    }
    
    func fetchBookcase(name: String, learningLanguageCode: String, meaningLanguageCode: String) -> Bookcase? {
        let request = NSFetchRequest<Bookcase>(entityName: "Bookcase")
        request.predicate = NSPredicate(format: "name == %@ AND learningLanguage == %@ AND meaningLanguage == %@", name, learningLanguageCode, meaningLanguageCode)
        request.fetchLimit = 1
        do {
            let bookcases = try viewContext.fetch(request)
            return bookcases.first
        } catch {
            print("Bookcase coduln't fetched \(error)")
            return nil
        }
    }
    
    func deleteBookcase(bookcase: Bookcase) {
        viewContext.delete(bookcase)
        save()
    }
    
    func createBook(learningWord: String,
                    meaningWord: String,
                    exampleSentence: String?,
                    descriptionWord: String?,
                    partOfSpeech: String?,
                    in bookcase: Bookcase) -> Book {
        let book = Book(context: viewContext)
        book.learningWord = learningWord
        book.meaningWord = meaningWord
        book.exampleSentence = exampleSentence
        book.descriptionWord = descriptionWord
        book.createdDate = Date()
        book.bookcase = bookcase
        book.partOfSpeech = partOfSpeech
        book.shortMemory = true
        save()
        let persistentBookID = book.objectID.uriRepresentation().absoluteString
        NotificationManager.shared.createNotification(bookId: persistentBookID, learningWord: learningWord, meaningWord: meaningWord, description: descriptionWord ?? "", example: exampleSentence ?? "")
        return book
    }
    
    enum ImportBookcaseError: Error {
        case alreadyExist
        case missingRequiredFields
    }
    
    
    func importBookcase(_ request: BookcaseRequest,
                        overwrite: Bool = true,
                        completion: @escaping (Result<Bookcase, ImportBookcaseError>) -> Void) {
        viewContext.perform {
            do {
                guard
                    let source = request.sourceLanguage,
                    let target = request.targetLanguage,
                    let name = request.name
                else { throw ImportBookcaseError.missingRequiredFields }
                
                let bookcaseName = name.uppercased()
                
                let bookcase: Bookcase
                if let existing = self.fetchBookcase(name: bookcaseName, learningLanguageCode: source, meaningLanguageCode: target) {
                    bookcase = existing
                    completion(.failure(.alreadyExist))
                    return
                } else {
                    bookcase = Bookcase(context: self.viewContext)
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
                        in: bookcase
                    )
                }
                
                self.save()
                completion(.success(bookcase))
                
            } catch {
                completion(.failure(.missingRequiredFields))
            }
        }
    }
    
    func fetchBooks(model: BookcaseModel, sortDescriptors: [NSSortDescriptor]? = nil) -> [Book]? {
        if let bookcase = fetchBookcase(
            name: model.bookcaseName,
            learningLanguageCode: model.learningLanguage,
            meaningLanguageCode: model.meaningLanguage
        ) {
            let request = NSFetchRequest<Book>(entityName: "Book")
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            request.predicate = NSPredicate(format: "bookcase == %@", bookcase)
            do {
                return try viewContext.fetch(request)
            } catch {
                print("Books couldn't fetched -> \(error)")
                return nil
            }
        }else {
            return nil
        }
    }
    
    func fetchBooks(bookcase: Bookcase, sortDescriptors: [NSSortDescriptor]? = nil) -> [Book]? {
        let request = NSFetchRequest<Book>(entityName: "Book")
        request.sortDescriptors = sortDescriptors ?? [
            NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
        ]
        request.predicate = NSPredicate(format: "bookcase == %@", bookcase)
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Books couldn't fetched -> \(error)")
            return nil
        }
    }
    
    func fetchAllBooksWithExampleDescription(sortDescriptors: [NSSortDescriptor]? = nil) -> [Book]? {
        let request = NSFetchRequest<Book>(entityName: "Book")
        request.sortDescriptors = sortDescriptors ?? [
            NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
        ]
        request.predicate = NSPredicate(format: "(exampleSentence != nil OR descriptionWord != nil)")
        do {
            return try viewContext.fetch(request)
        } catch {
            return nil
        }
    }
    
    func fetchBooksExampleDescription(model: BookcaseModel, sortDescriptors: [NSSortDescriptor]? = nil) -> [Book]? {
        if let bookcase = fetchBookcase(
            name: model.bookcaseName,
            learningLanguageCode: model.learningLanguage,
            meaningLanguageCode: model.meaningLanguage
        ){
            let request = NSFetchRequest<Book>(entityName: "Book")
            request.sortDescriptors = sortDescriptors ?? [
                NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
            ]
            request.predicate = NSPredicate(format: "bookcase == %@ AND (exampleSentence != nil OR descriptionWord != nil)", bookcase)
            do {
                return try viewContext.fetch(request)
            } catch {
                print("Books couldn't fetched -> \(error)")
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    func fetchBooksExampleDescription(bookcase: Bookcase, sortDescriptors: [NSSortDescriptor]? = nil) -> [Book]? {
        let request = NSFetchRequest<Book>(entityName: "Book")
        request.sortDescriptors = sortDescriptors ?? [
            NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
        ]
        request.predicate = NSPredicate(format: "bookcase == %@ AND (exampleSentence != nil OR descriptionWord != nil)", bookcase)
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Books couldn't fetched -> \(error)")
            return nil
        }
    }
    
    func deleteBook(book: Book) {
        viewContext.delete(book)
        let persistentBookID = book.objectID.uriRepresentation().absoluteString
        NotificationManager.shared.deleteNotification(bookId: persistentBookID)
        save()
    }
    
    func fetchAllBooks(sortDescriptors: [NSSortDescriptor]? = nil) -> [Book]? {
        let request = NSFetchRequest<Book>(entityName: "Book")
        request.sortDescriptors = sortDescriptors ?? [
            NSSortDescriptor(keyPath: \Book.createdDate, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            return nil
        }
    }
    
    func deleteEverything() {
        let entities = ["Book", "Bookcase"]
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try viewContext.execute(deleteRequest)
            } catch {
                print("Error in \(entity): \(error.localizedDescription)")
            }
        }
        save()
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
        
        manager.save()
        return manager
    }()
}
