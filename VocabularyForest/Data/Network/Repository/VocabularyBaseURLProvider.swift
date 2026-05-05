//
//  VocabularyBaseURLProvider.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 30.04.2026.
//

import Foundation
import FirebaseRemoteConfig

protocol VocabularyBaseURLProviderProtocol: AnyObject {
    func resolveVocabURL(completion: @escaping (String) -> Void)
    func resolveImageURL(completion: @escaping (String) -> Void)
}

final class VocabularyBaseURLProvider: VocabularyBaseURLProviderProtocol {
    private enum Keys {
        static let vocabularyBaseURL = "vocabulary_base_url"
        static let imageFetcherBaseURL = "image_fetcher_base_url"
    }

    private let remoteConfig: RemoteConfig
    private let fallbackBaseURL: String
    private let fallbackImageBaseURL: String

    init(
        remoteConfig: RemoteConfig = RemoteConfig.remoteConfig(),
        fallbackBaseURL: String = AppConfig.baseURL,
        fallbackImageBaseURL: String = "https://image-fetcher.yakupkavk.workers.dev/"
    ) {
        self.remoteConfig = remoteConfig
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        self.remoteConfig.configSettings = settings
        self.fallbackBaseURL = Self.normalizedBaseURL(from: fallbackBaseURL)
            ?? "https://vocab-api.yakupkavk.workers.dev/api/"
        self.fallbackImageBaseURL = Self.normalizedBaseURL(from: fallbackImageBaseURL)
            ?? "https://image-fetcher.yakupkavk.workers.dev/"
    }

    func resolveVocabURL(completion: @escaping (String) -> Void) {
        let cachedValue = remoteConfig.configValue(forKey: Keys.vocabularyBaseURL).stringValue

        remoteConfig.fetchAndActivate { [fallbackBaseURL] _, _ in
            let remoteValue = self.remoteConfig.configValue(forKey: Keys.vocabularyBaseURL).stringValue
            let resolvedBaseURL = Self.normalizedBaseURL(from: remoteValue)
                ?? Self.normalizedBaseURL(from: cachedValue)
                ?? fallbackBaseURL

            completion(resolvedBaseURL)
        }
    }

    func resolveImageURL(completion: @escaping (String) -> Void) {
        let cachedValue = remoteConfig.configValue(forKey: Keys.imageFetcherBaseURL).stringValue

        remoteConfig.fetchAndActivate { [fallbackImageBaseURL] _, _ in
            let remoteValue = self.remoteConfig.configValue(forKey: Keys.imageFetcherBaseURL).stringValue
            let resolvedBaseURL = Self.normalizedBaseURL(from: remoteValue)
                ?? Self.normalizedBaseURL(from: cachedValue)
                ?? fallbackImageBaseURL

            completion(resolvedBaseURL)
        }
    }

    private static func normalizedBaseURL(from rawValue: String?) -> String? {
        guard let rawValue else { return nil }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              (scheme == "https" || scheme == "http"),
              let host = components.host,
              !host.isEmpty else {
            return nil
        }

        let normalizedPath = components.path.hasSuffix("/") ? components.path : "\(components.path)/"
        components.path = normalizedPath

        return components.url?.absoluteString
    }
}
