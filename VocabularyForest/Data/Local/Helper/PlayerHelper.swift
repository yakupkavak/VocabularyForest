//
//  PlayerHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.04.2026.
//

import Foundation

// MARK: - CONSTANTS

private extension PlayerHelper {
    enum Constants {
        static let defaultNameKey = "Ichigo"
        static let lprojExtension = "lproj"
    }
}

struct PlayerHelper {
    static func createDefaultPlayer() -> PlayerModel {
        PlayerModel(name: localizedDefaultName(), lastUpdateDate: Date())
    }

    /// The stored name is frozen in whatever language the app was first launched in.
    /// If the user never renamed the player (the stored value equals the default name
    /// in any supported language), show the default name of the current language instead.
    static func displayName(for storedName: String) -> String {
        isDefaultName(storedName) ? localizedDefaultName() : storedName
    }
}

// MARK: - HELPERS

private extension PlayerHelper {

    static func localizedDefaultName() -> String {
        String(localized: String.LocalizationValue(Constants.defaultNameKey))
    }

    static func isDefaultName(_ name: String) -> Bool {
        Bundle.main.localizations.contains { localization in
            guard let path = Bundle.main.path(forResource: localization, ofType: Constants.lprojExtension),
                  let bundle = Bundle(path: path) else { return false }
            return bundle.localizedString(forKey: Constants.defaultNameKey, value: nil, table: nil) == name
        }
    }
}
