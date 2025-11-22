//
//  Resource.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

struct Resource<T> {
    let status: Status
    let data: T?
    let error: Error?
    
    static func success(data: T?) -> Resource {
        return Resource(status: .success, data: data, error: nil)
    }
    
    static func loading() -> Resource {
        return Resource(status: .loading, data: nil, error: nil)
    }
    
    static func error(error: Error?) -> Resource {
        return Resource(status: .error, data: nil, error: error)
    }
}

enum Status {
    case success
    case loading
    case error
}
