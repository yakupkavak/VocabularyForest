//
//  Book+CoreDataProperties.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.10.2025.
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
    @NSManaged public var learningWord: String?
    @NSManaged public var meaningWord: String?
    @NSManaged public var exampleSentence: String?
    @NSManaged public var descriptionWord: String?
    @NSManaged public var bookcase: Bookcase?
    
    public var unwrappedDate: Date {
        createdDate ?? Date()
    }
    public var unwrappedLearningWord: String {
        learningWord ?? "Sorry, here is empty"
    }
    public var unwrappedMeaningWord: String {
        meaningWord ?? "Sorry, here is empty"
    }
    public var unwrappedExampleSentence: String {
        exampleSentence ?? ""
    }
    public var unwrappedDescriptionWord: String{
        descriptionWord ?? ""
    }

}

extension Book : Identifiable {

}
