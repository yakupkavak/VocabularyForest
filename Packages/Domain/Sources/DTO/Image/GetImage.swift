//
//  GetImage.swift
//  Domain
//
//  Created by Yakup Kavak on 30.04.2026.
//


import Alamofire
import CoreAPI
import YakoSwift

@DefaultInit
public enum GetImage: EndPoint {
    
    case image(_ value: GetImageRequestModel, baseURL: String)
    
    public var baseURL: String {
        switch self {
        case .image(_, let baseURL):
            return baseURL
        }
    }
    
    public var path: String {
        switch self {
        case .image(let model, _):
            return model.imagePath
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
