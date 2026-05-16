//
//  RemoteConfigResponse.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.05.2026.
//

struct RemoteConfigResponse<T: Decodable> {
    let model: T
    let rawData: Any?
}
