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
    @State private var bookcaseName = ""
    @State private var selectedSpeech: SpeechModel? = nil
    @State private var vocabularyLanguage: Language? = nil
    @State private var meaningLanguage: Language? = nil
    @State private var currentBookcase = "Japonya"
    @State private var showInitalize = true
    @State private var activeSheet: SheetTypes? = nil
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = VocabularyMainViewModel()

    //MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem
                            .ignoresSafeArea()
            VStack {
                if showInitalize {
                    initalizeHeader
                    initalizeUser
                }else {
                    defaultHeader
                    textFields
                }
                Spacer()
            }.frame(minHeight: 0, maxHeight: .infinity)
        }
        .onChange(of: viewModel.updateUI) { preferences in
            if let preferences {
                
            }
        }
        .onChange(of: viewModel.showInitalize) { initalize in
            if let initalize {
                if initalize {
                    showInitalize = true
                }
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .learning:
                SelectLanguageUI(selectedLanguage: $vocabularyLanguage)
            case .meaning:
                SelectLanguageUI(selectedLanguage: $meaningLanguage)
            }
        }
    }
}

// MARK: - COMPONENTS

private extension VocabularyMainUI {
    var initalizeUser: some View {
        VStack(alignment: .leading ,spacing: 20) {
            tvDefault(text: "Bookcase name")
            VocabularyTextField(
                userInput: $bookcaseName,
                isSelected: .constant(focusedField == .bookcaseName),
                placeholder: "Daily words, hobbies, etc.",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .bookcaseName)
            tvDefault(text: "Learning language")
            Button(action: {
                activeSheet = .learning
            }) {
                LanguageRowUI(
                    language: vocabularyLanguage,
                    placeholder: "Select learning language"
                )
            }
            tvDefault(text: "Meaning language")
            Button(action: {
                activeSheet = .meaning
            }) {
                LanguageRowUI(
                    language: meaningLanguage,
                    placeholder: "Select meaning language"
                )
            }
            Spacer()
            Image("elephant").resizable().scaledToFit().frame(width: 100)
            Spacer()
            Button {
                createBookcase()
            } label: {
                Text("Create").padding(.vertical, 8).padding(.horizontal, 4).frame(maxWidth: .greatestFiniteMagnitude, alignment: .center)
            }.tint(Color.unselectedButton).buttonStyle(.bordered)

            Spacer()
        }.padding(24)
    }
    var textFields: some View {
        VStack(spacing: 20) {
            VocabularyTextField(
                userInput: $vocabularyTf,
                isSelected: .constant(focusedField == .vocabulary),
                placeholder: "What are you learning (Required)",
                title: vocabularyLanguage?.name,
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .vocabulary)
            
            VocabularyTextField(
                userInput: $meaningTf,
                isSelected: .constant(focusedField == .meaning),
                placeholder: "Meaning of that (Required)",
                title: meaningLanguage?.localizedName
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
    var initalizeHeader: some View {
        HStack{
            Spacer()
            tvHint(text: "Crate bookcase")
            Spacer()
        }
    }
    var defaultHeader: some View {
        HStack{
            Spacer()
            VStack{
                Button {
                    print("Boockase")
                } label: {
                    tvTitle(text: currentBookcase)
                }.foregroundStyle(.tint)
                tvHint(text: "Bookcase")
            }
            Spacer()
        }.overlay(alignment: .trailing) {
            Button {
                print("Added")
            } label: {
                Text("Add")
            }.offset(x: -24)
        }
        .overlay(alignment: .leading) {
            Button {
                print("Boockase")
            } label: {
                //TODO: - Add bookcase icon
                Image(systemName: "heart.fill").resizable().scaledToFit().frame(minWidth: 20, maxWidth: 34)
            }.offset(x: 24)
        }
    }
}

// MARK: - HELPERS

private extension VocabularyMainUI {
    func createBookcase() {
        
    }
}

// MARK: - CONSTANTS

private extension VocabularyMainUI {
    
    struct SpeechModel {
        var type: PartOfSpeech
        var color: Color
    }

    enum SheetTypes: Identifiable {
        case learning
        case meaning
        
        var id: Int {
            hashValue
        }
    }
    
    enum Field: Hashable {
        case vocabulary
        case meaning
        case sentence
        case description
        case bookcaseName
        case learningLanguage
        case meaningLanguage
    }

}

#Preview {
    VocabularyMainUI()
}
