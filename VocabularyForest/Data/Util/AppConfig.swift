//
//  AppConfig.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 31.12.2025.
//

import Foundation

struct AppConfig {
    static var baseURL: String {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("ApiBaseURL not found in Info.plist")
        }
        return urlString.replacingOccurrences(of: "\\", with: "")
    }
}
