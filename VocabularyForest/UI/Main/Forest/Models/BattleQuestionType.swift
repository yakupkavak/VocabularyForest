//
//  BattleGameType.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 24.11.2025.
//

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
            "Learning"
        case .competitive:
            "Competitive"
        case .remainder:
            "Remainder"
        }
    }
    
    var description: String {
        switch self {
        case .learning:
            "Play with only short term memory with description or example."
        case .competitive:
            "You will see short term memory and when you find correct it will be long term!"
        case .remainder:
            "Play with only long term memory."
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
