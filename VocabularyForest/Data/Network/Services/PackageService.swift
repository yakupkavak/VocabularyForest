//
//  PackageService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import Combine
import Foundation

enum PackageServiceError: LocalizedError {
    case unknownPackage

    var errorDescription: String? {
        switch self {
        case .unknownPackage:
            return String(localized: "This package is not available right now.")
        }
    }
}

protocol PackageServiceProtocol: AnyObject {
    var packageSectionPublisher: AnyPublisher<MarketPackageSectionModel?, Never> { get }

    /// Builds the package section from the market config; packages whose
    /// product App Store Connect does not know are dropped, and a fully empty
    /// result hides the section (safe before the store is configured).
    func convertRemotePackages(list: RemoteMarketListModel) async
    /// Runs the StoreKit purchase, grants the contents, finishes the
    /// transaction, and returns everything that was granted for the popup.
    func purchasePackage(_ package: MarketPackageModel) async throws -> [LocalRewardModel]
}

// MARK: - SERVICE

final class PackageService {

    // MARK: - PROPERTIES

    private let storeService: StorePurchaseServiceProtocol
    private let rewardRepository: RewardRepositoryProtocol
    private let chestRepository: ChestRepositoryProtocol
    private let logger: AppLoggerProtocol
    @Published private var packageSection: MarketPackageSectionModel?
    private var packagesByProductId: [String: MarketPackageModel] = [:]
    private var recoveryTask: Task<Void, Never>?

    // MARK: - INIT

    init(
        storeService: StorePurchaseServiceProtocol,
        rewardRepository: RewardRepositoryProtocol,
        chestRepository: ChestRepositoryProtocol,
        logger: AppLoggerProtocol = AppLogger.shared
    ) {
        self.storeService = storeService
        self.rewardRepository = rewardRepository
        self.chestRepository = chestRepository
        self.logger = logger
    }

    deinit {
        recoveryTask?.cancel()
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension PackageService: PackageServiceProtocol {

    var packageSectionPublisher: AnyPublisher<MarketPackageSectionModel?, Never> {
        $packageSection.eraseToAnyPublisher()
    }

    func convertRemotePackages(list: RemoteMarketListModel) async {
        guard let remoteSection = list.packages,
              let sectionId = remoteSection.id,
              let remoteItems = remoteSection.items, !remoteItems.isEmpty else {
            await publish(section: nil)
            return
        }

        let prices: [String: String]
        do {
            let ids = remoteItems.compactMap { $0.productId }
            prices = Dictionary(
                uniqueKeysWithValues: try await storeService.products(ids: ids).map { ($0.id, $0.displayPrice) }
            )
        } catch {
            logger.error("Store products could not be loaded: \(error.localizedDescription)", category: .reward)
            await publish(section: nil)
            return
        }

        var items: [MarketPackageModel] = []
        for remoteItem in remoteItems {
            guard let itemId = remoteItem.id,
                  let productId = remoteItem.productId,
                  let displayPrice = prices[productId],
                  let displayName = remoteItem.displayName,
                  let remoteContents = remoteItem.contents, !remoteContents.isEmpty else { continue }

            var contents: [LocalRewardModel] = []
            do {
                for remoteReward in remoteContents {
                    contents.append(try await rewardRepository.processAndGetLocalReward(from: remoteReward))
                }
            } catch {
                logger.error("Package contents could not be processed for \(itemId): \(error.localizedDescription)", category: .reward)
                continue
            }

            items.append(
                MarketPackageModel(
                    id: itemId,
                    productId: productId,
                    displayName: displayName.localized,
                    displayPrice: displayPrice,
                    contents: contents
                )
            )
        }

        packagesByProductId = Dictionary(uniqueKeysWithValues: items.map { ($0.productId, $0) })
        let section = items.isEmpty ? nil : MarketPackageSectionModel(
            id: sectionId,
            title: remoteSection.title?.localized ?? "",
            items: items
        )
        await publish(section: section)
        startTransactionRecoveryIfNeeded()
    }

    func purchasePackage(_ package: MarketPackageModel) async throws -> [LocalRewardModel] {
        let transaction = try await storeService.purchase(productId: package.productId)
        let granted = try await grantContents(of: package)
        await storeService.finishTransaction(id: transaction.id)
        return granted
    }
}

// MARK: - HELPERS

private extension PackageService {
    @MainActor
    func publish(section: MarketPackageSectionModel?) {
        packageSection = section
    }

    /// Grants every content of a package. Chest contents are opened once per
    /// count (each open advances the pity counter) and their drops are what
    /// the player actually receives.
    func grantContents(of package: MarketPackageModel) async throws -> [LocalRewardModel] {
        var granted: [LocalRewardModel] = []
        for content in package.contents {
            switch content.reward {
            case .chest(let chest):
                for _ in 0..<max(1, content.rewardCount) {
                    let drops = try await chestRepository.openChest(chestId: chest.id)
                    for drop in drops {
                        try await rewardRepository.claimLocalReward(reward: drop)
                    }
                    granted.append(contentsOf: drops)
                }
            case .standart:
                try await rewardRepository.claimLocalReward(reward: content)
                granted.append(content)
            }
        }
        return granted
    }

    /// Paid-but-unfinished transactions (app killed mid-grant, Ask to Buy)
    /// are re-granted here; only after a successful grant is the transaction
    /// finished, so a failing grant retries on the next launch.
    func startTransactionRecoveryIfNeeded() {
        guard recoveryTask == nil else { return }
        recoveryTask = Task { [weak self] in
            guard let stream = self?.storeService.unfinishedTransactions() else { return }
            for await transaction in stream {
                guard let self else { return }
                guard let package = packagesByProductId[transaction.productId] else {
                    logger.error("Unfinished transaction for unknown product \(transaction.productId)", category: .reward)
                    continue
                }
                do {
                    _ = try await grantContents(of: package)
                    await storeService.finishTransaction(id: transaction.id)
                } catch {
                    logger.error("Recovered purchase grant failed for \(transaction.productId): \(error.localizedDescription)", category: .reward)
                }
            }
        }
    }
}
