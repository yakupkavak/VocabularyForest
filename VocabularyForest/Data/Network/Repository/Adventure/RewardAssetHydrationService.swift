//
//  RewardAssetHydrationService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 16.07.2026.
//

import Foundation
import Combine

/// Result of a single hydration pass: how many assets were verified on disk and marked ready,
/// and how many could not be downloaded and stayed queued (assetReady == false).
struct AssetHydrationSummary: Equatable {
    var readyCount: Int = 0
    var pendingCount: Int = 0
}

enum AssetHydrationState: Equatable {
    case idle
    case running
    case finished(AssetHydrationSummary)
}

protocol RewardAssetHydrationServiceProtocol: AnyObject {
    var statePublisher: AnyPublisher<AssetHydrationState, Never> { get }

    /// Downloads the restored forest's assets that are missing on disk, verifies them on disk and
    /// marks the verified ones as `assetReady = true` in CoreData.
    @discardableResult
    func hydrateMissingAssets(for forest: SafeForestModel) async -> AssetHydrationSummary

    /// The queue is every CoreData entity with `assetReady == false`. Idempotent: it leaves ready
    /// entities alone and makes no network call for them, so splash and forest entry can both
    /// call it repeatedly without harm.
    @discardableResult
    func hydratePendingAssets() async -> AssetHydrationSummary

    /// Cancels every in-flight hydration pass. Already downloaded entities stay ready; the ones
    /// that did not finish stay queued (assetReady == false) and are retried on the next pass.
    func cancelActiveHydration()
}

// MARK: - CONSTANTS

private extension RewardAssetHydrationService {
    enum Constants {
        static let maxAttemptsPerSession = 3
    }
}

final class RewardAssetHydrationService {

    // MARK: - PROPERTIES

    private let assetDownloader: RewardAssetDownloaderProtocol
    private let remoteConfigRepository: RemoteConfigRepositoryProtocol
    private let offlineAssetManager: OfflineAssetManagerProtocol
    private let forestManager: ForestDataManagerProtocol
    private let queue: AssetHydrationQueueProtocol
    private let logger: AppLoggerProtocol

    // Subscribers must only see live transitions: a replayed `.finished` would close the restore
    // popup the moment it appears, so this is deliberately not a CurrentValueSubject.
    private let stateSubject = PassthroughSubject<AssetHydrationState, Never>()
    private let lock = NSLock()
    /// Per-asset attempt cap for the session, so an asset that keeps returning 404 does not
    /// hit the network on every screen entry.
    private var failureCounts: [String: Int] = [:]

    // MARK: - INIT

    init(
        assetDownloader: RewardAssetDownloaderProtocol,
        remoteConfigRepository: RemoteConfigRepositoryProtocol,
        offlineAssetManager: OfflineAssetManagerProtocol,
        forestManager: ForestDataManagerProtocol,
        queue: AssetHydrationQueueProtocol = AssetHydrationQueue(),
        logger: AppLoggerProtocol = AppLogger.shared
    ) {
        self.assetDownloader = assetDownloader
        self.remoteConfigRepository = remoteConfigRepository
        self.offlineAssetManager = offlineAssetManager
        self.forestManager = forestManager
        self.queue = queue
        self.logger = logger
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension RewardAssetHydrationService: RewardAssetHydrationServiceProtocol {

    var statePublisher: AnyPublisher<AssetHydrationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    @discardableResult
    func hydrateMissingAssets(for forest: SafeForestModel) async -> AssetHydrationSummary {
        await queue.enqueue { [weak self] in
            guard let self else { return AssetHydrationSummary() }
            return await self.performHydration(entities: self.pendingEntities(in: forest))
        }
    }

    @discardableResult
    func hydratePendingAssets() async -> AssetHydrationSummary {
        await queue.enqueue { [weak self] in
            guard let self,
                  let forest = self.forestManager.fetchSafeForest(contextType: .background).data else {
                return AssetHydrationSummary()
            }
            return await self.performHydration(entities: self.pendingEntities(in: forest))
        }
    }

    func cancelActiveHydration() {
        queue.cancelAll()
    }
}

// MARK: - HELPERS

private extension RewardAssetHydrationService {

    struct OfflineEntity {
        let assetName: String
        let rewardId: String?
        let poster: RewardAssetReference
    }

    func pendingEntities(in forest: SafeForestModel) -> [OfflineEntity] {
        var entities: [OfflineEntity] = []
        for tree in forest.trees where tree.assetSource == .offlineStorage && !tree.assetReady {
            entities.append(OfflineEntity(assetName: tree.assetName, rewardId: tree.rewardId, poster: tree.poster))
        }
        for animal in forest.animals where animal.assetSource == .offlineStorage && !animal.assetReady {
            entities.append(OfflineEntity(assetName: animal.assetName, rewardId: animal.rewardId, poster: animal.poster))
        }
        for sculpture in forest.sculptures where sculpture.assetSource == .offlineStorage && !sculpture.assetReady {
            entities.append(OfflineEntity(assetName: sculpture.assetName, rewardId: sculpture.rewardId, poster: sculpture.poster))
        }
        return entities
    }

    func performHydration(entities: [OfflineEntity]) async -> AssetHydrationSummary {
        var summary = AssetHydrationSummary()
        guard !entities.isEmpty else {
            stateSubject.send(.finished(summary))
            return summary
        }

        stateSubject.send(.running)

        // The catalog is fetched only when something actually needs downloading; disk verification never hits the network.
        var resolver: RewardCatalogResolver? = nil
        var catalogFetchFailed = false
        var processedAssetNames = Set<String>()
        var readyAssetNames: [String] = []

        for entity in entities {
            // Stop on cancellation; the distinct assets left unprocessed are counted once below,
            // and the flush after the loop keeps everything downloaded so far.
            if Task.isCancelled { break }
            guard processedAssetNames.insert(entity.assetName).inserted else { continue }

            // If the file already verifies on disk, mark it ready without going to the network.
            if isMainAssetOnDisk(assetName: entity.assetName) {
                readyAssetNames.append(entity.assetName)
                summary.readyCount += 1
                continue
            }

            guard attemptCount(for: entity.assetName) < Constants.maxAttemptsPerSession else {
                summary.pendingCount += 1
                continue
            }

            if resolver == nil && !catalogFetchFailed {
                resolver = await fetchCatalogResolver()
                catalogFetchFailed = resolver == nil
            }
            guard let catalogItem = resolver?.catalogItem(rewardId: entity.rewardId, assetName: entity.assetName) else {
                registerFailure(for: entity.assetName)
                summary.pendingCount += 1
                continue
            }

            if await hydrate(entity: entity, using: catalogItem) {
                readyAssetNames.append(entity.assetName)
                summary.readyCount += 1
            } else {
                registerFailure(for: entity.assetName)
                summary.pendingCount += 1
            }
        }

        let unprocessedNames = Set(entities.map(\.assetName)).subtracting(processedAssetNames)
        summary.pendingCount += unprocessedNames.count

        // One batched CoreData write per pass; runs on the cancellation path too, so the assets
        // that finished downloading stay ready.
        flushReadyAssets(readyAssetNames)
        stateSubject.send(.finished(summary))
        return summary
    }

    // MARK: - Verification

    /// On-disk asset verification: either the zip bundle folder or the single png is enough.
    func isMainAssetOnDisk(assetName: String) -> Bool {
        if offlineAssetManager.isZipAssetReady(bundleId: assetName) { return true }
        return (try? offlineAssetManager.isAssetReady(assetName: assetName)) == true
    }

    func flushReadyAssets(_ assetNames: [String]) {
        guard !assetNames.isEmpty else { return }
        let result = forestManager.markAssetsReady(assetNames: assetNames, contextType: .background)
        if result.status == .error {
            logger.error("Hydration could not persist assetReady flags for: \(assetNames.joined(separator: ", "))", category: .asset)
        }
    }

    func attemptCount(for assetName: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return failureCounts[assetName] ?? 0
    }

    func registerFailure(for assetName: String) {
        lock.lock()
        failureCounts[assetName] = (failureCounts[assetName] ?? 0) + 1
        lock.unlock()
    }

    // MARK: - Download

    func fetchCatalogResolver() async -> RewardCatalogResolver? {
        do {
            let response = try await remoteConfigRepository.fetchRewardsCatalog()
            let items = response.model.items ?? []
            guard !items.isEmpty else { return nil }
            return RewardCatalogResolver(items: items)
        } catch {
            logger.error("Hydration could not fetch the rewards catalog: \(error.localizedDescription)", category: .asset)
            return nil
        }
    }

    /// Downloads and verifies on disk; returns `true` only for a verified asset.
    /// A half-downloaded zip is never marked ready: if the download is cancelled or fails,
    /// verification fails too and the entity stays queued.
    func hydrate(entity: OfflineEntity, using catalogItem: RemoteRewardModel) async -> Bool {
        guard let sourceString = catalogItem.imageSource,
              let imageSource = ImageSource.convertImageSource(value: sourceString),
              let remotePath = catalogItem.remotePath,
              let version = catalogItem.remoteAssetVersion else {
            return false
        }

        do {
            switch imageSource {
            case .local:
                // The catalog says this is a bundled asset: there is nothing to download.
                return true
            case .remote:
                try await assetDownloader.downloadAndSaveImageIfNeeded(
                    remotePath: remotePath,
                    localKey: entity.assetName,
                    version: version
                )
                guard (try? offlineAssetManager.isAssetReady(assetName: entity.assetName)) == true else {
                    return false
                }
            case .zip:
                try await assetDownloader.downloadAndSaveZipIfNeeded(
                    remotePath: remotePath,
                    localKey: entity.assetName,
                    version: version
                )
                guard offlineAssetManager.isZipAssetReady(bundleId: entity.assetName) else {
                    return false
                }
            }

            // The poster is best-effort: once the main asset is ready, a poster failure must not keep the entity queued.
            if entity.poster.source == .offlineStorage, let posterIconPath = catalogItem.posterIconPath {
                try? await assetDownloader.downloadAndSaveImageIfNeeded(
                    remotePath: posterIconPath,
                    localKey: entity.poster.key,
                    version: version
                )
            }
            return true
        } catch {
            logger.error("Hydration download failed for asset \(entity.assetName): \(error.localizedDescription)", category: .asset)
            return false
        }
    }
}
