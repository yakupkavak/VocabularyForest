//
//  SelectBookcaseHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.01.2026.
//

import Foundation

func setBookcaseDefault(bookcase: Bookcase) {
    let userInfo: [String: Any] = [
            BookcaseNotificationConstants.createdBookcaseName: bookcase.unwrappedName,
            BookcaseNotificationConstants.createdBookcaseLearning: bookcase.unwrappedLearningLanguage,
            BookcaseNotificationConstants.createdBookcaseMeaning: bookcase.unwrappedmeaningLanguage
        ]
    UserDefaults.standard.setValue(bookcase.unwrappedName, forKey: BookcaseConstants.bookcase)
    UserDefaults.standard.setValue(bookcase.unwrappedLearningLanguage, forKey: BookcaseConstants.learningLanguage)
    UserDefaults.standard.setValue(bookcase.unwrappedmeaningLanguage, forKey: BookcaseConstants.meaningLanguage)
    NotificationCenter.default.post(name: .didCreateBookcase, object: nil, userInfo: userInfo)
}
