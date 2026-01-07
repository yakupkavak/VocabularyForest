//
//  BattleGameType.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.11.2025.
//
import Foundation

enum BattleQuestionType: Hashable, Codable {
    case learning // short memory words with their description or example
    case competitive // only short memory without description or example.  If we suceed on that word will become long memory.
    case remainder // only long memory words to practise.
} // For 2 weeks or for a month it will became short term memory.
// TODO: - SAY ENGLISH DESCRIPTION OR EXAMPLE TO USER

extension BattleQuestionType {
    
    var title: String {
        switch self {
        case .learning:
            String(localized: "Öğrenme")
        case .competitive:
            String(localized: "Rekabet")
        case .remainder:
            String(localized: "Hatırlama")
        }
    }
    
    var description: String {
        switch self {
        case .learning:
            return String(localized:"Sadece kısa süreli hafızandaki kelimelerle; açıklama veya örnek desteğiyle oyna.")
        case .competitive:
            return String(localized: "Kısa süreli hafızandaki kelimeleri gör; doğru bildikçe onları uzun süreli hafızana taşı!")
        case .remainder:
            return String(localized: "Sadece uzun süreli hafızandaki (öğrenilmiş) kelimelerle oyna.")
        }
    }
    
    var valueForCoreData: String {
        switch self {
        case .learning:
            "learning"
        case .competitive:
            "competitive"
        case .remainder:
            "remainder"
        }
    }
    
    static func convertFromCoreData(type: String?) -> BattleQuestionType {
        guard let type else { return .learning }
        return switch type {
            case "learning":
                .learning
            case "competitive":
                .competitive
            case "remainder":
                .remainder
            default:
                .learning
        }
    }
}
