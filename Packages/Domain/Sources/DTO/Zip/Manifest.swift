//
//  Manifest.swift
//  Domain
//
//  Created by Yakup Kavak on 30.05.2026.
//

public struct ManifestModel: Decodable {
    public let bundleId: String?
    public let version: String?
    public let format: String?
    public let posterFrame: String?
    public let animations: AnimalAnimations?
}

public struct AnimalAnimations: Codable {
    public let idle: [String]?
    public let walk: [String]?
    public let jump: [String]?
    public let fly: [String]?
}
