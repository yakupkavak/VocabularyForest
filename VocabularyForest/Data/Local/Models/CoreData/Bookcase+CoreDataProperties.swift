//
//  Bookcase+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
//
//

public import Foundation
public import CoreData


public typealias BookcaseCoreDataPropertiesSet = NSSet

extension Bookcase {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookcase> {
        return NSFetchRequest<Bookcase>(entityName: "Bookcase")
    }

    @NSManaged public var createdDate: Date?
    @NSManaged public var learningLanguage: String?
    @NSManaged public var meaningLanguage: String?
    @NSManaged public var name: String?
    @NSManaged public var books: NSSet?

    public var unwrappedName: String {
        name ?? "Unknown name"
    }
    
    public var unwrappedLearningLanguage: String {
        learningLanguage ?? "Unknown language"
    }
    
    public var unwrappedmeaningLanguage: String {
        meaningLanguage ?? "Unknown language"
    }
    
    public var unwrappedDate: Date {
        createdDate ?? Date()
    }
    
    public var booksArray: [Book] {
        let booksSet = books as? Set<Book> ?? []
        return booksSet.sorted {
            $0.unwrappedDate < $1.unwrappedDate
        }
    }
    
    public var longMemoryBooksCount: Int {
        let booksSet = books as? Set<Book> ?? []
        return booksSet.filter({
            $0.longMemory == true
        }).count
    }
    
    public var shortMemoryBooksCount: Int {
        let booksSet = books as? Set<Book> ?? []
        return booksSet.filter({
            $0.shortMemory == true
        }).count
    }
    
    public var totalBooksCount: Int {
        let booksSet = books as? Set<Book> ?? []
        return booksSet.count
    }
    
    public var longMemoryBooks: [Book] {
        let booksSet = books as? Set<Book> ?? []
        return Array(booksSet)
    }
    
    public var shortMemoryBooks: [Book] {
        let booksSet = books as? Set<Book> ?? []
        return Array(booksSet)
    }
}

// MARK: Generated accessors for books

extension Bookcase {

    @objc(addBooksObject:)
    @NSManaged public func addToBooks(_ value: Book)

    @objc(removeBooksObject:)
    @NSManaged public func removeFromBooks(_ value: Book)

    @objc(addBooks:)
    @NSManaged public func addToBooks(_ values: NSSet)

    @objc(removeBooks:)
    @NSManaged public func removeFromBooks(_ values: NSSet)

}

extension Bookcase : Identifiable {

}
