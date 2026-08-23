//
//  ForestSyncCursorStore.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

import Foundation

protocol ForestSyncCursorStoring: AnyObject {
    /// Newest Firestore server timestamp this device has already seen. nil forces the
    /// next delta sync to do a one-time full pull (first run, or fallback after a restore
    /// of legacy cloud data that has no server stamps yet).
    var pullCursor: Date? { get set }
    func reset()
}

// MARK: - CONSTANTS

private extension ForestSyncCursorStore {
    enum Constants {
        static let pullCursorKey = "forestSyncPullCursor"
    }
}

final class ForestSyncCursorStore {

    // MARK: - PROPERTIES

    private let defaults: UserDefaults

    // MARK: - INIT

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension ForestSyncCursorStore: ForestSyncCursorStoring {

    var pullCursor: Date? {
        get { defaults.object(forKey: Constants.pullCursorKey) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Constants.pullCursorKey)
            } else {
                defaults.removeObject(forKey: Constants.pullCursorKey)
            }
        }
    }

    func reset() {
        defaults.removeObject(forKey: Constants.pullCursorKey)
    }
}
