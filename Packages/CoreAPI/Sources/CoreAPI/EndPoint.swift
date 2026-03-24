//
//  EndPoint.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation

public protocol EndPoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any & Sendable] { get }
    var headers: [String: String] { get }
}

public extension EndPoint {
    var headers: [String: String] { [:] }
    var parameters: [String: Any & Sendable] { [:] }
    var url: String {
        "\(baseURL)\(path)"
    }
}
