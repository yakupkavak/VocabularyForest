
//
//  GetLibraries.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Alamofire

enum GetLibraries: EndPoint {
    
    case standart
    
    var baseURL: String {
        return AppConfig.baseURL
    }
    
    var path: String {
        "libraries"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var parameters: [String: Any] {
        return [:]
    }
    
    var headers: [String: String] {
        [:]
    }
}
