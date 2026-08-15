//
//  SyncConflictResolverTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

@testable import VocabularyForest
import Foundation
import Testing

extension SyncResolution: Equatable where Model: Equatable {
    public static func == (lhs: SyncResolution<Model>, rhs: SyncResolution<Model>) -> Bool {
        switch (lhs, rhs) {
        case (.skip, .skip): return true
        case (.applyRemote(let left), .applyRemote(let right)): return left == right
        case (.pushLocal(let left), .pushLocal(let right)): return left == right
        default: return false
        }
    }
}

@Suite("Sync Conflict Resolver Tests", .tags(.system))
struct SyncConflictResolverTests {

    private struct StampedName: SyncTimestamped, Equatable {
        let name: String
        let lastUpdatedDate: Date
    }

    private let sut: SyncConflictResolving = LastWriteWinsConflictResolver()
    private let lastSync = Date(timeIntervalSince1970: 1_000)

    private func stamped(_ name: String, at seconds: TimeInterval) -> StampedName {
        StampedName(name: name, lastUpdatedDate: Date(timeIntervalSince1970: seconds))
    }

    @Test("Rename from another device replaces the stale local name")
    func remoteRenameWins() {
        // Device A renamed the fox to Jacob long ago; device B renamed it to Yakup afterwards.
        let local = stamped("Jacob", at: 500)
        let remote = stamped("Yakup", at: 2_000)

        #expect(sut.resolve(local: local, remote: remote, lastSyncDate: lastSync) == .applyRemote(remote))
    }

    @Test("Newer local edit beats an older cloud copy")
    func newerLocalEditWins() {
        let local = stamped("Yakup", at: 3_000)
        let remote = stamped("Jacob", at: 2_000)

        #expect(sut.resolve(local: local, remote: remote, lastSyncDate: lastSync) == .pushLocal(local))
    }

    @Test("Equal timestamps are the same write and produce no work")
    func equalTimestampsSkip() {
        let local = stamped("Yakup", at: 2_000)
        let remote = stamped("Yakup", at: 2_000)

        #expect(sut.resolve(local: local, remote: remote, lastSyncDate: lastSync) == .skip)
    }

    @Test("Local change with a quiet cloud is pushed")
    func localOnlyChangeIsPushed() {
        let local = stamped("Yakup", at: 2_000)

        #expect(sut.resolve(local: local, remote: nil, lastSyncDate: lastSync) == .pushLocal(local))
    }

    @Test("Unchanged local entity with a quiet cloud produces no work")
    func unchangedLocalSkips() {
        let local = stamped("Jacob", at: 500)

        #expect(sut.resolve(local: local, remote: nil, lastSyncDate: lastSync) == .skip)
    }

    @Test("Entity created on another device is applied locally")
    func remoteOnlyEntityIsApplied() {
        let remote = stamped("Yakup", at: 2_000)

        #expect(sut.resolve(local: nil, remote: remote, lastSyncDate: lastSync) == .applyRemote(remote))
    }

    @Test("Missing on both sides produces no work")
    func bothMissingSkips() {
        #expect(sut.resolve(local: nil, remote: StampedName?.none, lastSyncDate: lastSync) == .skip)
    }
}
