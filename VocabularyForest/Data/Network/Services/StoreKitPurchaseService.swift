//
//  StoreKitPurchaseService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.08.2026.
//

import Foundation
import StoreKit

enum StorePurchaseError: LocalizedError {
    case productNotFound
    case failedVerification
    case purchasePending
    case purchaseCancelled

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return String(localized: "This package is not available right now.")
        case .failedVerification:
            return String(localized: "Purchase could not be verified. Please try again.")
        case .purchasePending:
            return String(localized: "Your purchase is waiting for approval.")
        case .purchaseCancelled:
            return nil
        }
    }
}

/// StoreKit-agnostic view of a verified transaction; the id is what
/// `finishTransaction` needs to close it after the content is granted.
struct StoreTransactionModel: Hashable {
    let id: UInt64
    let productId: String
}

struct StoreProductModel: Hashable {
    let id: String
    /// Localized price string straight from the store (e.g. "$1.99")
    let displayPrice: String
}

protocol StorePurchaseServiceProtocol: AnyObject {
    func products(ids: [String]) async throws -> [StoreProductModel]
    /// Runs the purchase flow and returns the VERIFIED transaction. The caller
    /// must grant the content first and then call `finishTransaction`.
    func purchase(productId: String) async throws -> StoreTransactionModel
    func finishTransaction(id: UInt64) async
    /// Verified consumable transactions that were paid but never finished
    /// (app killed mid-grant, Ask to Buy approvals, renewals) — emitted once
    /// for the backlog, then live as they arrive.
    func unfinishedTransactions() -> AsyncStream<StoreTransactionModel>
}

// MARK: - SERVICE

final class StoreKitPurchaseService {

    // MARK: - PROPERTIES

    private var cachedProducts: [String: Product] = [:]
}

// MARK: - PROTOCOL CONFORMANCE

extension StoreKitPurchaseService: StorePurchaseServiceProtocol {
    func products(ids: [String]) async throws -> [StoreProductModel] {
        let products = try await Product.products(for: ids)
        for product in products {
            cachedProducts[product.id] = product
        }
        return products.map { StoreProductModel(id: $0.id, displayPrice: $0.displayPrice) }
    }

    func purchase(productId: String) async throws -> StoreTransactionModel {
        let product: Product
        if let cached = cachedProducts[productId] {
            product = cached
        } else {
            guard let fetched = try await Product.products(for: [productId]).first else {
                throw StorePurchaseError.productNotFound
            }
            cachedProducts[productId] = fetched
            product = fetched
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            return StoreTransactionModel(id: transaction.id, productId: transaction.productID)
        case .pending:
            throw StorePurchaseError.purchasePending
        case .userCancelled:
            throw StorePurchaseError.purchaseCancelled
        @unknown default:
            throw StorePurchaseError.productNotFound
        }
    }

    func finishTransaction(id: UInt64) async {
        for await verification in Transaction.unfinished {
            guard case .verified(let transaction) = verification, transaction.id == id else { continue }
            await transaction.finish()
            return
        }
    }

    func unfinishedTransactions() -> AsyncStream<StoreTransactionModel> {
        AsyncStream { continuation in
            let task = Task {
                for await verification in Transaction.unfinished {
                    if case .verified(let transaction) = verification {
                        continuation.yield(StoreTransactionModel(id: transaction.id, productId: transaction.productID))
                    }
                }
                for await verification in Transaction.updates {
                    if case .verified(let transaction) = verification {
                        continuation.yield(StoreTransactionModel(id: transaction.id, productId: transaction.productID))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - HELPERS

private extension StoreKitPurchaseService {
    func verified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw StorePurchaseError.failedVerification
        }
    }
}
