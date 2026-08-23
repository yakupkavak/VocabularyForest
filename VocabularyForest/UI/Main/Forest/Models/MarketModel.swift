//
//  MarketModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 9.07.2026.
//

import Foundation

enum MarketCurrency: Hashable {
    case gold
    case diamond
    
    var iconName: String {
        switch self {
        case .gold:
            "gold_icon"
        case .diamond:
            "diamond_icon"
        }
    }
}

extension MarketCurrency {
    static func convertCurrency(value: String) -> Self? {
        return switch value {
        case "gold":
                .gold
        case "diamond":
                .diamond
        default:
            nil
        }
    }
}

struct MarketPriceModel: Hashable {
    let currency: MarketCurrency
    let amount: Int
}

struct MarketItemModel: Identifiable, Hashable {
    let id: String
    let price: MarketPriceModel
    let reward: LocalRewardModel
}

struct MarketSectionModel: Identifiable, Hashable {
    let id: String
    let title: String
    let items: [MarketItemModel]
}

struct MarketScreenModel {
    let title: String
    let sections: [MarketSectionModel]
}
