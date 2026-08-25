//
//  ConfigLoadFailure.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.08.2026.
//

import Foundation

/// Remote Config sections loaded during adventure setup.
/// Raw values match the Remote Config keys and are a binding contract
/// with the Android mirror and the `remote_config_load_failed` event.
enum RemoteConfigSection: String {
    case configParameters = "config_list"
    case rewardsCatalog = "rewards_config"
    case chest = "chest_rewards_config"
    case adventureRoad = "adventure_road_rewards_config"
    case market = "market_config"
    case dailySpin = "daily_spin_rewards_config"
    case quests = "quests_config"
    case weeklyRewards = "weekly_rewards_config"
    case gameEconomy = "game_economy_config"
}

/// `reason` parameter alphabet for the `remote_config_load_failed` event.
enum ConfigFailureReason: String {
    case fetchFailed = "fetch_failed"
    case decodeFailed = "decode_failed"
    case dataMissing = "data_missing"
    case internetRequired = "no_internet_initial_setup"
    case network = "network"
    case unknown = "unknown"
}

// MARK: - CONSTANTS

private extension ConfigLoadFailure {
    enum Constants {
        /// GA4 caps event parameter values at 100 characters.
        static let maxDetailLength = 100
        static let codingPathSeparator = "."
    }
}

// MARK: - CONFIG LOAD FAILURE

struct ConfigLoadFailure: Equatable {

    let section: RemoteConfigSection
    let reason: ConfigFailureReason
    let detail: String

    init(section: RemoteConfigSection, error: Error) {
        self.section = section

        switch error {
        case let remoteError as RemoteConfigError:
            switch remoteError {
            case .fetchFailed:
                reason = .fetchFailed
            case .decodeFailed:
                reason = .decodeFailed
            case .dataMissing:
                reason = .dataMissing
            case .internetRequiredForInitialSetup:
                reason = .internetRequired
            }
            detail = Self.truncated(String(describing: remoteError))
        case let decodingError as DecodingError:
            reason = .decodeFailed
            detail = Self.truncated(Self.describe(decodingError))
        case is URLError:
            reason = .network
            detail = Self.truncated(String(describing: error))
        default:
            let nsError = error as NSError
            reason = nsError.domain == NSURLErrorDomain ? .network : .unknown
            detail = Self.truncated("\(nsError.domain)(\(nsError.code)): \(nsError.localizedDescription)")
        }
    }
}

// MARK: - HELPERS

private extension ConfigLoadFailure {

    /// Compact, locale-independent description that names the failing coding
    /// path so the analytics event pinpoints which field broke decoding.
    static func describe(_ error: DecodingError) -> String {
        switch error {
        case let .keyNotFound(key, context):
            return "keyNotFound(\(key.stringValue)) at \(path(context))"
        case let .typeMismatch(type, context):
            return "typeMismatch(\(type)) at \(path(context))"
        case let .valueNotFound(type, context):
            return "valueNotFound(\(type)) at \(path(context))"
        case let .dataCorrupted(context):
            return "dataCorrupted at \(path(context)): \(context.debugDescription)"
        @unknown default:
            return String(describing: error)
        }
    }

    static func path(_ context: DecodingError.Context) -> String {
        let joined = context.codingPath
            .map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }
            .joined(separator: Constants.codingPathSeparator)
        return joined.isEmpty ? "root" : joined
    }

    static func truncated(_ value: String) -> String {
        String(value.prefix(Constants.maxDetailLength))
    }
}
