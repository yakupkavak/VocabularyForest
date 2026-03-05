//
//  UpperCase.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 7.01.2026.
//

import Foundation

extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { return prefix(1).capitalized + dropFirst() }
}
