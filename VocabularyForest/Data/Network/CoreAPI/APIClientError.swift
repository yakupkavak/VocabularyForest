//
//  APIClientError.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

public protocol APIError: Decodable {
    var message: String { get }
    var debugMessage: String { get }
    var code: Int { get }
    var result: Bool { get }
    var error: String { get }
    var id: String { get }
}

struct ClientError: APIError {
    var error: String
    var id: String
    var message: String
    var debugMessage: String
    var code: Int
    var result: Bool
}

public enum APIClientError: Error {
    case handledError(error: APIError)
    case networkError
    case decoding(error: DecodingError?)
    case timeout
    case message(String)
    
    public var message: String {
        return switch self {
        case .handledError(let error):
            error.message
        case .networkError:
            String(localized: "Bağlantı hatası")
        case .decoding(let error):
            String(localized:"Decode Hatası Oluştu: \(String(describing: error))")
        case .timeout:
            String(localized: "İstek zaman aşımına uğradı")
        case .message(let message):
            message
        }
    }
    
    public var debugMessage: String {
        switch self {
        case .handledError(let error):
            return error.message
        case .networkError:
            return "Bağlantı hatası"
        case .decoding(let error):
            guard let error else { return "Decode error" }
            return "\(error)"
        case .timeout:
            return "Zaman aşımı hatası"
        case .message(let message):
            return message
        }
    }
    
    public var title: String {
        return "Error"
    }
    
    public var code: Int {
        switch self {
        case .handledError(let error):
            return error.code
        default:
            return 500
        }
    }
}
