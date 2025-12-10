//
//  QuestionModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.11.2025.
//

import Foundation

struct QuestionModel: Hashable {
    let id = UUID()
    let questionTitle: String
    let answers: [AnswerModel]
    let questionNumber: Int
    let description: String? = nil
    let example: String? = nil
}

struct AnswerModel: Hashable {
    let answer: String
    var isTrue: Bool
}
