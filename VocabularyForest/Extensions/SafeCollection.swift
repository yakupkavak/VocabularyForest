//
//  SafeCollection.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 19.11.2025.
//

import Foundation

public extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
