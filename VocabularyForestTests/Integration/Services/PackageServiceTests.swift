//
//  PackageServiceTests.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

@testable import VocabularyForest
import Foundation
import Testing

// MARK: - MOCKS

final class MockStorePurchaseService: StorePurchaseServiceProtocol {
    var knownProducts: [StoreProductModel] = []
    var purchaseResult: Result<StoreTransactionModel, Error> = .failure(StorePurchaseError.productNotFound)
    var finishedTransactionIds: [UInt64] = []

    func products(ids: [String]) async throws -> [StoreProductModel] {
        knownProducts.filter { ids.contains($0.id) }
    }

    func purchase(productId: String) async throws -> StoreTransactionModel {
        try purchaseResult.get()
    }

    func finishTransaction(id: UInt64) async {
        finishedTransactionIds.append(id)
    }

    func unfinishedTransactions() -> AsyncStream<StoreTransactionModel> {
        AsyncStream { $0.finish() }
    }
}

final class MockChestRepository: ChestRepositoryProtocol {
    var openChestCallCount = 0
    var openChestResult: [LocalRewardModel] = []

    func getLocalChest(chestId: String) -> LocalChestModel? { nil }
    func processAndSaveChests(from remoteChests: [RemoteChestModel]) async throws {}
    func registerRewardCatalog(items: [RemoteRewardModel]) {}
    func openChest(chestId: String) async throws -> [LocalRewardModel] {
        openChestCallCount += 1
        return openChestResult
    }
    func fetchChestDropInfo(chestId: String) async throws -> [ChestDropInfoModel] { [] }
    func pityProgress(chestId: String) -> ChestPityProgressModel? { nil }
}

// MARK: - TESTS

@Suite("Package Service Tests", .tags(.gameLogic))
struct PackageServiceTests {

    let sut: PackageServiceProtocol
    let storeService: MockStorePurchaseService
    let rewardRepository: MockRewardRepository
    let chestRepository: MockChestRepository

    init() {
        storeService = MockStorePurchaseService()
        rewardRepository = MockRewardRepository()
        chestRepository = MockChestRepository()
        sut = PackageService(
            storeService: storeService,
            rewardRepository: rewardRepository,
            chestRepository: chestRepository
        )
    }

    private var chestContentPackage: MarketPackageModel {
        let chest = LocalChestModel(
            id: "chest-diamond",
            version: 1,
            displayName: RemoteLocalizedText(tr: "Elmas Sandık", en: "Diamond Chest", es: nil, fr: nil, de: nil, pt: nil),
            closeLocalImagePath: RewardAssetReference(key: "closed", source: .appAssets),
            openLocalImagePath: RewardAssetReference(key: "open", source: .appAssets),
            textHexColor: nil,
            backgroundGradientColors: nil
        )
        return MarketPackageModel(
            id: "package-seed",
            productId: "com.bootcamp.vocabularyforest.iap.pack.seed",
            displayName: "Seed Bundle",
            displayPrice: "$1.99",
            contents: [
                LocalRewardModel(rewardCount: 2, reward: .chest(model: chest)),
                LocalRewardModel.mock(rewardCount: 60)
            ]
        )
    }

    @Test("Successful purchase opens every chest, claims all drops, and finishes the transaction")
    func successfulPurchaseGrantsContents() async throws {
        storeService.purchaseResult = .success(StoreTransactionModel(id: 42, productId: "com.bootcamp.vocabularyforest.iap.pack.seed"))
        chestRepository.openChestResult = [LocalRewardModel.mock(rewardCount: 250)]

        let granted = try await sut.purchasePackage(chestContentPackage)

        #expect(chestRepository.openChestCallCount == 2)
        // 2 chest drops + 1 direct diamond content
        #expect(rewardRepository.claimCallCount == 3)
        #expect(granted.count == 3)
        #expect(storeService.finishedTransactionIds == [42])
    }

    @Test("Cancelled purchase grants nothing")
    func cancelledPurchaseGrantsNothing() async {
        storeService.purchaseResult = .failure(StorePurchaseError.purchaseCancelled)

        await #expect(throws: StorePurchaseError.self) {
            try await sut.purchasePackage(chestContentPackage)
        }
        #expect(rewardRepository.claimCallCount == 0)
        #expect(storeService.finishedTransactionIds.isEmpty)
    }

    @Test("Failed grant leaves the transaction unfinished so it can be recovered")
    func failedGrantKeepsTransactionOpen() async {
        storeService.purchaseResult = .success(StoreTransactionModel(id: 7, productId: "com.bootcamp.vocabularyforest.iap.pack.seed"))
        rewardRepository.errorToThrow = RewardRepositoryError.decodingError
        chestRepository.openChestResult = [LocalRewardModel.mock()]

        await #expect(throws: Error.self) {
            try await sut.purchasePackage(chestContentPackage)
        }
        #expect(storeService.finishedTransactionIds.isEmpty)
    }
}
