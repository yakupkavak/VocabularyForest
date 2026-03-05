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
    let description: String?
    let example: String?
}

struct AnswerModel: Hashable {
    let book: BookModel?
    let answer: String
    var isTrue: Bool
}
