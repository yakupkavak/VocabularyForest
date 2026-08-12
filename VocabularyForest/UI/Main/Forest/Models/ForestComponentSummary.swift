//
//  ForestComponentSummary.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 12.08.2026.
//

import Foundation

/// Lightweight projection of a scene entity for the SwiftUI management list —
/// the Voice Control-friendly alternative to tapping SpriteKit nodes.
struct ForestComponentSummary: Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: ComponentType

    /// Moving is driven by UpdatePositionProtocol, which animals don't
    /// implement (they roam on their own), so the list only offers it
    /// for plants and sculptures.
    var supportsMove: Bool { type != .animal }
}
