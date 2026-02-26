//
//  SelectBookcaseHelper.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.01.2026.
//

import Foundation

func setBookcaseDefault(bookcase: BookcaseModel) {
    let userInfo: [String: Any] = [
            BookcaseNotificationConstants.createdBookcaseName: bookcase.bookcaseName,
            BookcaseNotificationConstants.createdBookcaseLearning: bookcase.learningLanguage,
            BookcaseNotificationConstants.createdBookcaseMeaning: bookcase.meaningLanguage
        ]
    UserDefaults.standard.setValue(bookcase.bookcaseName, forKey: BookcaseConstants.bookcase)
    UserDefaults.standard.setValue(bookcase.learningLanguage, forKey: BookcaseConstants.learningLanguage)
    UserDefaults.standard.setValue(bookcase.meaningLanguage, forKey: BookcaseConstants.meaningLanguage)
    NotificationCenter.default.post(name: .didCreateBookcase, object: nil, userInfo: userInfo)
}
