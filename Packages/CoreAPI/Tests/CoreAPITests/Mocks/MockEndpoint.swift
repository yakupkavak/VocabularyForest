//
//  MockEndpoint.swift
//  CoreAPI
//
//  Created by Yakup Kavak on 12.06.2026.
//

import Alamofire
@testable import CoreAPI

struct MockEndpoint: EndPoint {
    var baseURL: String = "https://test.com"
    var path: String = "/test"
    var method: HTTPMethod = .get
}

struct MockModel: Decodable, Sendable {
    let id: String
    let name: String
}
