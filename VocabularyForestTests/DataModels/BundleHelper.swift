//
//  BundleHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.06.2026.
//
@testable import VocabularyForest
import Foundation

final class TestBundleHelper{}

extension TestBundleHelper {
    @MainActor
    static func loadMockJSON<T: Decodable>(filename: String, model: T.Type) throws -> T {
        let url = Bundle(for: TestBundleHelper.self).url(forResource: filename, withExtension: "json")!
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    @MainActor
    static func fetchMockJSON(filename: String) throws -> Data {
        let url = Bundle(for: TestBundleHelper.self).url(forResource: filename, withExtension: "json")!
        return try Data(contentsOf: url)
    }
}
