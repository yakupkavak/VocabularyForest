//
//  RandomAnimal.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.10.2025.
//

func getRandomAnimalModel() -> AnimalBodyModel {
    let animals = [("elephanthead", "elephantfoot"), ("cowhead","cowfoot"), ("pandahead","pandafoot")]
    if let randomAnimal = animals.randomElement() {
        return AnimalBodyModel(head: randomAnimal.0, foot: randomAnimal.1)
    }
    return AnimalBodyModel(head: "elephantHead", foot: "elephantFoot")
}
