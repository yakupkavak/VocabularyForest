//
//  GetBookcase.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Alamofire
import CoreAPI

public enum GetBookcase: EndPoint {
    
    case definition(_ value: GetBookcaseRequestModel, baseURL: String)

    public var baseURL: String {
        switch self {
        case .definition(_, let baseURL):
            return baseURL
        }
    }
    
    public var path: String {
        switch self {
        case .definition(let value, _):
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
