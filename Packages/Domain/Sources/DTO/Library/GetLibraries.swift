
//
//  GetLibraries.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Alamofire
import CoreAPI

public enum GetLibraries: EndPoint {
    
    case standart(baseURL: String)
    
    public var baseURL: String {
        switch self {
        case .standart(let baseURL):
            return baseURL
        }
    }
    
    public var path: String {
        "libraries"
    }
    
    public var method: HTTPMethod {
        .get
    }
    
    var parameters: [String: Any] {
        return [:]
    }
    
    public var headers: [String: String] {
        [:]
    }
}
