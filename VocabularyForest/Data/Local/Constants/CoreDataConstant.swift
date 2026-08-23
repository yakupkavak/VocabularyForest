//
//  CoreDataConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 31.01.2026.
//

enum CoreDataConstant {
    static let bookEntityName = "Book"
    static let bookcaseEntityName = "Bookcase"
    static let bookcaseRelationName = "bookcase"
    static let entities = ["Book","Bookcase"]
    /// Everything the cloud account owns; vocabulary (Book/Bookcase) is device-only and excluded.
    static let forestEntities = ["Forest", "Tree", "Animal", "Sculpture", "Quest", "Player", "DailyActivities"]
    static let forestAssetEntityNames = ["Animal", "Tree", "Sculpture"]
    static let assetNameKey = "assetName"
    static let assetReadyKey = "assetReady"
    static let forestRelationName = "forest"
}
