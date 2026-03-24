//
//  GetBookcaseRequestModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//
import YakoSwift

public struct GetBookcaseRequestModel {
    public let bookcaseID: String

    public init(bookcaseID: String) {
        self.bookcaseID = bookcaseID
    }
}
