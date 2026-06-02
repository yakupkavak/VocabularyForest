//
//  networkError.swift
//  Domain
//
//  Created by Yakup Kavak on 30.05.2026.
//

import Alamofire
import CoreAPI
import YakoSwift

@DefaultInit
public enum GetZip: EndPoint {
    
    case zip(_ value: GetZipRequestModel, baseURL: String)
    
    public var baseURL: String {
        switch self {
        case .zip(_, let baseURL):
            return baseURL
        }
    }
    
    public var path: String {
        switch self {
        case .zip(let model, _):
            return model.remotePath
        }
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
