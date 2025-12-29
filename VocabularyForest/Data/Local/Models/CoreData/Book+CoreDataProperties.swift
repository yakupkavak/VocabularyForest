//
//  Book+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.10.2025.
//
//

public import Foundation
public import CoreData


public typealias BookCoreDataPropertiesSet = NSSet

extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var createdDate: Date?
    @NSManaged public var learningDate: Date?
    @NSManaged public var descriptionWord: String?
    @NSManaged public var exampleSentence: String?
    @NSManaged public var learningWord: String?
    @NSManaged public var meaningWord: String?
    @NSManaged public var longMemory: Bool
    @NSManaged public var shortMemory: Bool
    @NSManaged public var bookcase: Bookcase?
    @NSManaged public var partOfSpeech: String?
    
    public var unwrappedDate: Date {
        createdDate ?? Date()
    }
    public var unwrappedLearningWord: String {
        learningWord ?? ""
    }
    public var unwrappedMeaningWord: String {
        meaningWord ?? ""
    }
    public var unwrappedPartOfSpeech: String {
        partOfSpeech ?? ""
    }
}

extension Book : Identifiable {

}
