//
//  CoreExtensions.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 27.01.2026.
//

@preconcurrency import CoreData

extension NSManagedObjectContext {
    func fetch<Entity, Result>(request: NSFetchRequest<Entity>) async -> [Result]? where Entity: NSManagedObject, Entity: ConvertSafeModel, Result == Entity.SafeModel {
        do {
            return try await self.perform { [weak self] in
                try self?.fetch(request).compactMap { try $0.safeObject() } ?? []
            }
        }catch {
            print(error.localizedDescription)
        }
        return nil
    }
}

protocol MatchCoreData {
    var valueForCoreData: String { get }
    static func convertFromCoreData(value: String?) -> Self
}

protocol ConvertSafeModel {
    associatedtype SafeModel
    func safeObject() throws -> SafeModel
}

enum SafeModelError: Error {
    case invalidMapping
    case emptyValue
}
