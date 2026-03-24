//
//  GetBookcase.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Alamofire
import CoreAPI
import YakoSwift

public enum GetBookcase: EndPoint {
    
    case definition(_ value: GetBookcaseRequestModel)

    public var baseURL: String {
        return "https://vocab-api.yakupkavk.workers.dev/api/"
    }
    
    public var path: String {
        switch self {
        case .definition(let value):
            "library/\(value.bookcaseID)"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
            case .definition:
                return .get
        }
    }
    
    var parameters: [String: Any] {
        return [:]
    }
    
    public var headers: [String: String] {
        [:]
    }
}
