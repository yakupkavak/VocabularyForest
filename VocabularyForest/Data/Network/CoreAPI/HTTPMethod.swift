//
//  HTTPMethod.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation
import Alamofire

public typealias HTTPMethod = Alamofire.HTTPMethod

public extension EndPoint {
    var encoding: ParameterEncoding {
        switch method {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
}
