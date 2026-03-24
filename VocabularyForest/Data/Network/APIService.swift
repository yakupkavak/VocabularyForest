//
//  APIService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import CoreAPI
import DTO

typealias BookcaseRequestResult = Result<BookcaseRequest, APIClientError>
typealias LibrariesResult = Result<Libraries, APIClientError>

protocol APIServiceProtocol: AnyObject {
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void)
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void)
}

public class APIService: APIServiceProtocol {
    
    // MARK: - PROPERTIES
    
    let bookcaseRequestManager = NetworkManager<GetBookcase>()
    let librariesManager = NetworkManager<GetLibraries>()
    
    // MARK: - HELPERS
    
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void) {
        bookcaseRequestManager.request(endpoint: .definition(values), type: BookcaseRequest.self) { result in
            completion(result)
        }
    }
    
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void) {
        librariesManager.request(endpoint: .standart, type: Libraries.self) { result in
            completion(result)
        }
    }
    
}
