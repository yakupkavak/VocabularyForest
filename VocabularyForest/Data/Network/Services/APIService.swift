//
//  APIService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import CoreAPI
import DTO
import Foundation
import Alamofire

typealias BookcaseRequestResult = Result<BookcaseRequest, APIClientError>
typealias LibrariesResult = Result<Libraries, APIClientError>
typealias ImageResult = Result<Data, APIClientError>
typealias ZipResult = Result<Data, APIClientError>

protocol APIServiceProtocol: AnyObject {
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void)
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void)
    func fetchImage(values: GetImageRequestModel,completion: @escaping (ImageResult) -> Void)
    func fetchZip(values: GetZipRequestModel, completion: @escaping(ZipResult) -> Void)
}

public class APIService: APIServiceProtocol {
    
    // MARK: - PROPERTIES
    
    let bookcaseRequestManager = NetworkManager<GetBookcase>()
    let librariesManager = NetworkManager<GetLibraries>()
    let imageManager = NetworkManager<GetImage>()
    let zipManager = NetworkManager<GetZip>()
    private let vocabularyBaseURLProvider: VocabularyBaseURLProviderProtocol
    
    // MARK: - INIT

    init(
        vocabularyBaseURLProvider: VocabularyBaseURLProviderProtocol = VocabularyBaseURLProvider(),
        session: Alamofire.Session = .default
    ) {
        self.vocabularyBaseURLProvider = vocabularyBaseURLProvider
    }
    
    // MARK: - HELPERS
    
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void) {
        vocabularyBaseURLProvider.resolveVocabURL { [weak self] baseURL in
            guard let self else { return }

            bookcaseRequestManager.request(endpoint: .definition(values, baseURL: baseURL), type: BookcaseRequest.self) { result in
                completion(result)
            }
        }
    }
    
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void) {
        vocabularyBaseURLProvider.resolveVocabURL { [weak self] baseURL in
            guard let self else { return }
            librariesManager.request(endpoint: .standart(baseURL: baseURL), type: Libraries.self) { result in
                completion(result)
            }
        }
    }
    
    func fetchImage(values: GetImageRequestModel, completion: @escaping (ImageResult) -> Void) {
        vocabularyBaseURLProvider.resolveImageURL { [weak self] baseURL in
            guard let self else { return }
            imageManager.requestData(endpoint: .image(values, baseURL: baseURL)) { result in
                completion(result)
            }
        }
    }
    
    func fetchZip(values: GetZipRequestModel, completion: @escaping(ZipResult) -> Void) {
        vocabularyBaseURLProvider.resolveImageURL { [weak self] baseURL in
            guard let self else { return }
            zipManager.requestData(endpoint: .zip(values, baseURL: baseURL)) { result in
                completion(result)
            }
        }
    }
}
