//
//  NetworkTimeHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.04.2026.
//

import Foundation

// MARK: - TIME FETCH ERROR

enum TimeFetchError: LocalizedError {
    case offline
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return String(localized: "İnternet bağlantınız yok. Ödüllerinizi almak için lütfen bağlantınızı kontrol edip tekrar deneyin.")
        case .invalidResponse:
            return String(localized: "Sunucu saati alınamadı. Lütfen daha sonra tekrar deneyin.")
        }
    }
}

class NetworkTimeHelper {
    static func getTrueTime() async throws -> Date {
        guard let url = URL(string: "https://www.google.com") else {
            throw TimeFetchError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 5.0
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let dateString = httpResponse.allHeaderFields["Date"] as? String else {
                throw TimeFetchError.invalidResponse
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            guard let realDate = formatter.date(from: dateString) else {
                throw TimeFetchError.invalidResponse
            }
            
            return realDate
            
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain &&
              (nsError.code == NSURLErrorNotConnectedToInternet || nsError.code == NSURLErrorTimedOut) {
                throw TimeFetchError.offline
            }
            throw TimeFetchError.invalidResponse
        }
    }
}
