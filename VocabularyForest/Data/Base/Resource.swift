//
//  Resource.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

struct Resource<T> {
    let status: Status
    let data: T?
    let error: Error? = nil
    
    static func success(data: T?) -> Resource {
        return Resource(status: .success, data: data)
    }
    
    static func loading() -> Resource {
        return Resource(status: .loading, data: nil)
    }
    
    static func error(data: T?) -> Resource {
        return Resource(status: .error, data: data)
    }
}

enum Status {
    case success
    case loading
    case error
}
