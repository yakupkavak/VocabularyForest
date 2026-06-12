//
//  NetworkManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation
import Alamofire

public typealias Completion<T> = @Sendable (Result<T, APIClientError>) -> Void where T: Decodable

public final class NetworkManager<EndpointItem: EndPoint> {
    
    private let session: Session
    
    // MARK: - INIT
    
    public init(session: Session = .default) {
        self.session = session
    }
    
    private var possibleEmptyResponseCodes: Set<Int> {
        var defaultSet = DataResponseSerializer.defaultEmptyResponseCodes
        defaultSet.insert(200)
        defaultSet.insert(201)
        return defaultSet
    }
    
    public func request<T: Decodable & Sendable>(endpoint: EndpointItem, type: T.Type, completion: @escaping Completion<T>) {
        if (!Reachability.isConnectedToNetwork()) {
            completion(.failure(.networkError))
            return
        }
        self.session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: HTTPHeaders(endpoint.headers),
        )
        .validate()
        .response(responseSerializer: DataResponseSerializer(emptyResponseCodes: possibleEmptyResponseCodes)) { response in
            switch response.result {
            case .success(let data):
                do {
                    let decodedObject = try JSONDecoder().decode(type, from: data)
                    completion(.success(decodedObject))
                } catch {
                    let decodingError = APIClientError.decoding(error: error as? DecodingError)
                    completion(.failure(decodingError))
                }
            case .failure(let error):
                if NSURLErrorTimedOut == (error as NSError).code {
                    completion(.failure(.timeout))
                } else {
                    guard let data = response.data else {
                        completion(.failure(.networkError))
                        return
                    }
                    do {
                        let clientError = try JSONDecoder().decode(ClientError.self, from: data)
                        completion(.failure(.handledError(error: clientError)))
                    } catch {
                        let decodingError = APIClientError.decoding(error: error as? DecodingError)
                        completion(.failure(decodingError))
                    }
                }
            }
        }
    }
    
    public func requestData(endpoint: EndpointItem, completion: @escaping @Sendable (Result<Data, APIClientError>) -> Void) {
        if (!Reachability.isConnectedToNetwork()) {
            completion(.failure(.networkError))
            return
        }
        
        AF.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: HTTPHeaders(endpoint.headers)
        )
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                if NSURLErrorTimedOut == (error as NSError).code {
                    completion(.failure(.timeout))
                } else {
                    completion(.failure(.networkError))
                }
            }
        }
    }
}
