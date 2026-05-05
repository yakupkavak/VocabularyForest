//
//  APIService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import CoreAPI
import DTO
import Foundation

typealias BookcaseRequestResult = Result<BookcaseRequest, APIClientError>
typealias LibrariesResult = Result<Libraries, APIClientError>
typealias ImageResult = Result<Data, APIClientError>
typealias AnimalResult = Result<AnimalBundleModel, APIClientError>

protocol APIServiceProtocol: AnyObject {
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void)
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void)
    func fetchImage(values: GetImageRequestModel,completion: @escaping (ImageResult) -> Void)
    func fetchAnimal(values: GetAnimalRequestModel, completion: @escaping (AnimalResult) -> Void)
}

public class APIService: APIServiceProtocol {
    
    // MARK: - PROPERTIES
    
    let bookcaseRequestManager = NetworkManager<GetBookcase>()
    let librariesManager = NetworkManager<GetLibraries>()
    let imageManager = NetworkManager<GetImage>()
    let animalManager = NetworkManager<GetAnimal>()
    private let vocabularyBaseURLProvider: VocabularyBaseURLProviderProtocol
    
    // MARK: - INIT

    init(vocabularyBaseURLProvider: VocabularyBaseURLProviderProtocol = VocabularyBaseURLProvider()) {
        self.vocabularyBaseURLProvider = vocabularyBaseURLProvider
    }
    
    // MARK: - HELPERS
    
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void) {
        vocabularyBaseURLProvider.resolveVocabURL { [weak self] baseURL in
            guard let self else { return }

            self.bookcaseRequestManager.request(endpoint: .definition(values, baseURL: baseURL), type: BookcaseRequest.self) { result in
                completion(result)
            }
        }
    }
    
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void) {
        vocabularyBaseURLProvider.resolveVocabURL { [weak self] baseURL in
            guard let self else { return }
            self.librariesManager.request(endpoint: .standart(baseURL: baseURL), type: Libraries.self) { result in
                completion(result)
            }
        }
    }
    
    func fetchImage(values: GetImageRequestModel, completion: @escaping (ImageResult) -> Void) {
        vocabularyBaseURLProvider.resolveImageURL { [weak self] baseURL in
            guard let self else { return }
            self.imageManager.requestData(endpoint: .image(values, baseURL: baseURL)) { result in
                completion(result)
            }
        }
    }

    func fetchAnimal(values: GetAnimalRequestModel, completion: @escaping (AnimalResult) -> Void) {
        vocabularyBaseURLProvider.resolveImageURL { [weak self] baseURL in
            guard let self else { return }

            self.animalManager.requestData(endpoint: .animal(values, baseURL: baseURL)) { result in
                switch result {
                case .success(let data):
                    do {
                        let animalBundle = try GetAnimal.decode(data: data)
                        completion(.success(animalBundle))
                    } catch {
                        completion(.failure(.message(error.localizedDescription)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
