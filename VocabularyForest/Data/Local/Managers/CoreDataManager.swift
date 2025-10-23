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
    }
    
    // MARK: - HELPERS
    
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
    
    func fetchBookcase(name: String) -> Bookcase? {
        let request = NSFetchRequest<Bookcase>(entityName: "Bookcase")
        request.predicate = NSPredicate(format: "name == %@", name)
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
                    in bookcase: Bookcase) -> Book {
        let book = Book(context: viewContext)
        book.learningWord = learningWord
        book.meaningWord = meaningWord
        book.exampleSentence = exampleSentence
        book.descriptionWord = descriptionWord
        book.createdDate = Date()
        book.bookcase = bookcase
        save()
        return book
    }
    
    func deleteBook(book: Book) {
        viewContext.delete(book)
        save()
    }
}

extension CoreDataManager {
    
    static var preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let context = manager.viewContext
        
        let sampleBookcase = Bookcase(context: context)
        sampleBookcase.name = "Preview bookcase"
        sampleBookcase.createdDate = Date()
        sampleBookcase.learningLanguage = "ja"
        sampleBookcase.meaningLanguage = "tr"
        
        let sampleBook = Book(context: context)
        sampleBook.learningWord = "Konnichiwa"
        sampleBook.meaningWord = "Merhaba"
        sampleBook.createdDate = Date()
        sampleBook.exampleSentence = "Konnichiwa, sensei!"
        sampleBook.bookcase = sampleBookcase
        
        manager.save()
        return manager
    }()
}
