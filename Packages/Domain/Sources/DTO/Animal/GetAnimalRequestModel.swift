//
//  GetAnimalRequestModel.swift
//  Domain
//
//  Created by Yakup Kavak on 4.05.2026.
//

public struct GetAnimalRequestModel {
    public let animalPath: String

    public init(animalPath: String) {
        self.animalPath = animalPath
    }
}
