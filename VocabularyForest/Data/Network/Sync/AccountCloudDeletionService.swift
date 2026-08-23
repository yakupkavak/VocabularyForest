//
//  AccountCloudDeletionService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 15.08.2026.
//

import FirebaseFirestore
import FirebaseAuth

protocol AccountCloudDeletionServiceProtocol: AnyObject {
    /// Account deletion flow: wipes all of the user's Firestore data and unlinks
    /// the local forest from the account.
    func deleteCloudData() async throws
}

// MARK: - CONSTANTS

private extension AccountCloudDeletionService {
    enum Constants {
        // Firestore caps a batch at 500 writes, so deletes are chunked below that.
        static let deleteChunkSize = 400
    }
}

final class AccountCloudDeletionService {

    // MARK: - PROPERTIES

    private let db: Firestore
    private let cursorStore: ForestSyncCursorStoring
    private let dataManager: ForestDataManagerProtocol

    // MARK: - INIT

    init(db: Firestore, cursorStore: ForestSyncCursorStoring, dataManager: ForestDataManagerProtocol) {
        self.db = db
        self.cursorStore = cursorStore
        self.dataManager = dataManager
    }
}

// MARK: - PROTOCOL CONFORMANCE

extension AccountCloudDeletionService: AccountCloudDeletionServiceProtocol {

    func deleteCloudData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw ForestSyncError.unauthenticated }

        let userDoc = db.collection(ForestSyncConstants.usersCollection).document(uid)
        let forestDoc = userDoc
            .collection(ForestSyncConstants.forestsCollection)
            .document(ForestSyncConstants.mainForestDocument)

        let subcollections = [
            ForestSyncConstants.treesCollection,
            ForestSyncConstants.animalsCollection,
            ForestSyncConstants.sculpturesCollection,
            ForestSyncConstants.questsCollection,
            ForestSyncConstants.playerCollection,
            ForestSyncConstants.dailyRewardsCollection
        ]

        do {
            try await deleteSubcollections(subcollections, under: forestDoc)
            let finalBatch = db.batch()
            finalBatch.deleteDocument(forestDoc)
            finalBatch.deleteDocument(userDoc)
            try await finalBatch.commit()
        } catch {
            throw ForestSyncError.firestoreError(error)
        }

        // The cloud forest is gone; a stale cursor would hide documents a future
        // account uploads with older server timestamps.
        cursorStore.reset()
        _ = dataManager.bindForestToUser(uid: nil, contextType: .main)
    }
}

// MARK: - HELPERS

private extension AccountCloudDeletionService {

    func deleteSubcollections(_ collectionNames: [String], under parentDoc: DocumentReference) async throws {
        for collectionName in collectionNames {
            let documents = try await parentDoc.collection(collectionName).getDocuments().documents
            for chunkStart in stride(from: 0, to: documents.count, by: Constants.deleteChunkSize) {
                let batch = db.batch()
                documents[chunkStart..<min(chunkStart + Constants.deleteChunkSize, documents.count)].forEach {
                    batch.deleteDocument($0.reference)
                }
                try await batch.commit()
            }
        }
    }
}
