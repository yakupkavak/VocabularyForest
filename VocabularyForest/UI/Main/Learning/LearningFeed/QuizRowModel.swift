//
//  QuizRowModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

struct QuizRowModel: Hashable{
    let leftImage: String
    let rightImage: String
    let quizType: QuizType
}

enum QuizType: Hashable{
    case flashCard
    case forest
}
