//
//  TalkConstant.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 14.03.2026.
//

import Foundation

enum TalkConstant {
    
    enum Animal {
        static let drought: [String] = [
            String(localized: "I have no energy left to move, need some water..."),
            String(localized: "I'm so thirsty..."),
            String(localized: "Everything is so dry around here..."),
            String(localized: "Where did all the water go?"),
            String(localized: "I need a drink to keep going...")
        ]
        
        static let normal: [String] = [
            String(localized: "The forest is beautiful today!"),
            String(localized: "Let's run around!"),
            String(localized: "My belly is full, life is good."),
            String(localized: "What a lovely day to play!"),
            String(localized: "I love hanging out in this forest.")
        ]
    }
    
    enum Plant {
        static let drought: [String] = [
            String(localized: "I need water to revive..."),
            String(localized: "My leaves are drying up, please give me water..."),
            String(localized: "So thirsty... I can't breathe."),
            String(localized: "I can't grow without a drop of water..."),
            String(localized: "The soil is turning into dust...")
        ]
        
        static let normal: [String] = [
            String(localized: "The sun feels amazing!"),
            String(localized: "My roots feel incredibly strong today."),
            String(localized: "The fresh air is simply wonderful."),
            String(localized: "I feel like I'm growing taller every day!"),
            String(localized: "So much beautiful green around us!")
        ]
    }
    
    enum Sculpture {
        static let drought: [String] = [
            String(localized: "I might crack from this unbearable heat..."),
            String(localized: "The ground is bone dry..."),
            String(localized: "Even stone feels the pain of this drought."),
            String(localized: "We desperately need some rain..."),
            String(localized: "The sun is completely unforgiving today.")
        ]
        
        static let normal: [String] = [
            String(localized: "I have been standing here for years."),
            String(localized: "The silence of the forest is beautiful."),
            String(localized: "I am the silent guardian of this forest."),
            String(localized: "Such peaceful and ancient vibes."),
            String(localized: "Watching over the trees is my duty.")
        ]
    }
}
