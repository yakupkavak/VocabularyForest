
//
//  GetLibraries.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Alamofire
import CoreAPI
import YakoSwift

@DefaultInit
public enum GetLibraries: EndPoint {
    
    case standart
    
    public var baseURL: String {
        return "https://vocab-api.yakupkavk.workers.dev/api/"
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
