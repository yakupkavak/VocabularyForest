//
//  FeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

struct VocabularyMainUI: View {
    
    //MARK: - PROPERTIES
    
    @State private var vocabularyTf = ""
    @State private var meaningTf = ""
    @State private var sentenceTf = ""
    @State private var descriptionTf = ""
    @State private var selectedSpeech: SpeechModel? = nil
    @State var vocabularyLanguage: Languages = .englishUS
    @State var meaningLanguage: Languages = .turkish
    @FocusState private var focusedField: Field?

    //MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem
                            .ignoresSafeArea()
            VStack {
                HStack{
                    Spacer()
                    Text("Başlık")
                    Spacer()
                }.overlay(alignment: .trailing) {
                    Button {
                        print("Added")
                    } label: {
                        Text("Add")
                    }.offset(x: -24)
                }
                textFields
                Spacer()
            }.frame(minHeight: 0, maxHeight: .infinity)
        }
    }
}

// MARK: - COMPONENTS

private extension VocabularyMainUI {
    var textFields: some View {
        VStack(spacing: 20) {
            VocabularyTextField(
                userInput: $vocabularyTf,
                isSelected: .constant(focusedField == .vocabulary),
                placeholder: "What are you learning (required)",
                title: vocabularyLanguage.localizedText,
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .vocabulary)
            
            VocabularyTextField(
                userInput: $meaningTf,
                isSelected: .constant(focusedField == .meaning),
                placeholder: "Meaning of that (required)",
                title: meaningLanguage.localizedText
            ).focused($focusedField, equals: .meaning)
            
            VocabularyTextField(
                userInput: $descriptionTf,
                isSelected: .constant(focusedField == .description),
                placeholder: "Write the description",
                title: "Description",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .description)
            
            VocabularyTextField(
                userInput: $sentenceTf,
                isSelected: .constant(focusedField == .sentence),
                placeholder: "Example sentence",
                title: "Sentence"
            ).focused($focusedField, equals: .sentence)
        }.padding(24)
    }
}

// ASK: - Where should i store these models

struct SpeechModel {
    var type: PartOfSpeech
    var color: Color
}

enum PartOfSpeech: String {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case preposition
    case conjunction
    case interjection
    case determiner
    
    var localizedText: String {
        switch self {
        case .noun:
            return "Noun"
        case .verb:
            return "Verb"
        case .adjective:
            return "Adjective"
        case .adverb:
            return "Adverb"
        case .pronoun:
            return "Pronoun"
        case .preposition:
            return "Preposition"
        case .conjunction:
            return "Conjuction"
        case .interjection:
            return "Interjection"
        case .determiner:
            return "Determiner"
        }
    }
}

enum Languages: String {
    case turkish
    case englishUS
    case englishUK

    var localizedText: String {
        switch self {
        case .turkish:
            "Turkish"
        case .englishUS:
            "English (US)"
        case .englishUK:
            "English (UK)"
        }
    }
}


private enum Field: Hashable {
    case vocabulary
    case meaning
    case sentence
    case description
}

#Preview {
    VocabularyMainUI()
}
