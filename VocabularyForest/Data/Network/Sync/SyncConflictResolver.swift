//
//  SyncConflictResolver.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

import Foundation

/// Anything the delta sync can reconcile between the local forest and its cloud copy.
protocol SyncTimestamped {
    var lastUpdatedDate: Date { get }
}

enum SyncResolution<Model> {
    /// The cloud copy is newer; write it into CoreData keeping the remote timestamp.
    case applyRemote(Model)
    /// The local copy is newer; upload it to Firestore.
    case pushLocal(Model)
    case skip
}

protocol SyncConflictResolving: AnyObject {
    func resolve<Model: SyncTimestamped>(local: Model?, remote: Model?, lastSyncDate: Date) -> SyncResolution<Model>
}

// MARK: - RESOLVER

/// Entity-level last-write-wins: whichever side carries the newer user edit
/// (lastUpdatedDate) survives on both devices.
final class LastWriteWinsConflictResolver {}

// MARK: - PROTOCOL CONFORMANCE

extension LastWriteWinsConflictResolver: SyncConflictResolving {

    func resolve<Model: SyncTimestamped>(local: Model?, remote: Model?, lastSyncDate: Date) -> SyncResolution<Model> {
        switch (local, remote) {
        case (nil, nil):
            return .skip
        case (nil, .some(let remote)):
            return .applyRemote(remote)
        case (.some(let local), nil):
            // Nothing changed in the cloud since the cursor: push only what this
            // device edited after its last successful sync.
            return local.lastUpdatedDate > lastSyncDate ? .pushLocal(local) : .skip
        case (.some(let local), .some(let remote)):
            if local.lastUpdatedDate > remote.lastUpdatedDate { return .pushLocal(local) }
            if remote.lastUpdatedDate > local.lastUpdatedDate { return .applyRemote(remote) }
            // Equal timestamps mean the same write seen from both sides.
            return .skip
        }
    }
}

// MARK: - MODEL CONFORMANCES

extension TreeModel: SyncTimestamped {}
extension AnimalModel: SyncTimestamped {}
extension SculptureModel: SyncTimestamped {}
extension QuestTrackModel: SyncTimestamped {}
extension DailyActivitiesModel: SyncTimestamped {}
extension ForestMetadataUpdate: SyncTimestamped {}

extension PlayerModel: SyncTimestamped {
    var lastUpdatedDate: Date { lastUpdateDate }
}
