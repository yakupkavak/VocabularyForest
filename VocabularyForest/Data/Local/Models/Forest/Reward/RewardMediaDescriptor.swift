//
//  RewardMediaDescriptor.swift
//  VocabularyForest
//
//  Created by Codex on 3.05.2026.
//

import Foundation

enum RewardMediaSourceType: String, Codable {
    case localAsset = "local_asset"
    case remoteBundle = "remote_bundle"
}

enum RewardMediaFileType: String, Codable {
    case image
    case zip
}

struct RewardMediaDescriptor: Codable, Equatable {
    let sourceType: RewardMediaSourceType
    let fileType: RewardMediaFileType
    let previewImageURL: String?
    let sourceFieldKey: String?
    let sourceVersion: String?

    init(
        sourceType: RewardMediaSourceType,
        fileType: RewardMediaFileType,
        previewImageURL: String?,
        sourceFieldKey: String?,
        sourceVersion: String?
    ) {
        self.sourceType = sourceType
        self.fileType = fileType
        self.previewImageURL = previewImageURL
        self.sourceFieldKey = sourceFieldKey
        self.sourceVersion = sourceVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sourceType = try container.decodeIfPresent(RewardMediaSourceType.self, forKey: .sourceType) ?? .localAsset
        let fileType = try container.decodeIfPresent(RewardMediaFileType.self, forKey: .fileType)

        self.sourceType = sourceType
        self.fileType = fileType ?? (sourceType == .remoteBundle ? .zip : .image)
        self.previewImageURL = try container.decodeIfPresent(String.self, forKey: .previewImageURL)
        self.sourceFieldKey = try container.decodeIfPresent(String.self, forKey: .sourceFieldKey)
        self.sourceVersion = try container.decodeIfPresent(String.self, forKey: .sourceVersion)
    }

    private enum CodingKeys: String, CodingKey {
        case sourceType
        case fileType
        case previewImageURL
        case sourceFieldKey
        case sourceVersion
    }
}
