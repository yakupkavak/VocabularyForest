//
//  CountryNameStringExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.10.2025.
//

extension String {
    func getCountryName() -> String{
        let name = LanguageData.allLanguages.filter {
            $0.id == self
        }
        return name.first?.localizedName ?? ""
    }
}
