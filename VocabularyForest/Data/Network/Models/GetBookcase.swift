//
//  GetBookcase.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Alamofire

enum GetBookcase: EndPoint {
    
    case definition(_ value: GetBookcaseRequestModel)

    var baseURL: String {
        return "https://vocab-api.yakupkavk.workers.dev/api/"
    }
    
    var path: String {
        switch self {
        case .definition(let value):
            "library/\(value.bookcaseID)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
            case .definition:
                return .get
        }
    }
    
    var parameters: [String: Any] {
        return [:]
    }
    
    var headers: [String: String] {
        [:]
    }
}
