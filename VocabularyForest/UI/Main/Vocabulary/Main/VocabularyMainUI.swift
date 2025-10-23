//
//  FeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import Lottie

struct VocabularyMainUI: View {
    
    //MARK: - PROPERTIES

    @State private var activeSheet: SheetTypes? = nil
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = VocabularyMainViewModel()

    //MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem
                            .ignoresSafeArea()
            VStack {
                if viewModel.showInitalize {
                    initalizeHeader
                    initalizeUser
                }else {
                    defaultHeader
                    textFields
                }
                Spacer()
            }.frame(minHeight: 0, maxHeight: .infinity)
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .learning:
                SelectLanguageUI(selectedLanguage: $viewModel.learningLanguage)
            case .meaning:
                SelectLanguageUI(selectedLanguage: $viewModel.meaningLanguage)
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
                userInput: $viewModel.bookcaseName,
                isSelected: .constant(focusedField == .bookcaseName),
                isEmpty: $viewModel.emptyInitialBookcase,
                placeholder: "Daily words, hobbies, etc.",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .bookcaseName)
            tvDefault(text: "Learning language")
            Button(action: {
                activeSheet = .learning
            }) {
                LanguageRowUI(
                    isEmpty: $viewModel.emptyInitialVocabularyLanguage,
                    language: viewModel.learningLanguage,
                    placeholder: "Select learning language"
                )
            }.buttonStyle(.plain)
            tvDefault(text: "Meaning language")
            Button(action: {
                activeSheet = .meaning
            }) {
                LanguageRowUI(
                    isEmpty: $viewModel.emptyInitialMeaningLanguage,
                    language: viewModel.meaningLanguage,
                    placeholder: "Select meaning language"
                )
            }.buttonStyle(.plain)
            Spacer()
            HStack{
                Spacer()
                LottieView(animation: .named("meditationSloth"))
                    .playing(loopMode: .loop).resizable().frame(maxWidth: 250)
                Spacer()
            }
            
            Spacer()
            Button {
                viewModel.checkAndCreateBookcase()
            } label: {
                Text("Create").padding(.vertical, 8).padding(.horizontal, 4).frame(maxWidth: .greatestFiniteMagnitude, alignment: .center)
            }.tint(Color.unselectedButton).buttonStyle(.bordered)

            Spacer()
        }.padding(24)
    }
    var textFields: some View {
        VStack(spacing: 20) {
            VocabularyTextField(
                userInput: $viewModel.bookLearningWord,
                isSelected: .constant(focusedField == .vocabulary),
                isEmpty: $viewModel.emptyBookLearningWord,
                placeholder: "What are you learning (Required)",
                title: viewModel.learningLanguage?.name,
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .vocabulary)
            
            VocabularyTextField(
                userInput: $viewModel.bookMeaningWord,
                isSelected: .constant(focusedField == .meaning),
                isEmpty: $viewModel.emptyBookMeaningWord,
                placeholder: "Meaning of that (Required)",
                title: viewModel.meaningLanguage?.localizedName
            ).focused($focusedField, equals: .meaning)
            
            VocabularyTextField(
                userInput: $viewModel.bookDescription,
                isSelected: .constant(focusedField == .description),
                isEmpty: .constant(false),
                placeholder: "Write the description",
                title: "Description",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .description)
            
            VocabularyTextField(
                userInput: $viewModel.bookExampleSentence,
                isSelected: .constant(focusedField == .sentence),
                isEmpty: .constant(false),
                placeholder: "Example sentence",
                title: "Sentence"
            ).focused($focusedField, equals: .sentence)
        }.padding(24)
    }
    var initalizeHeader: some View {
        HStack{
            Spacer()
            tvSubtitle(text: "Crate bookcase")
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
                    tvTitle(text: viewModel.currentBookcase?.unwrappedName ?? "Unexpected error")
                }.foregroundStyle(.tint)
                tvHint(text: "Bookcase")
            }
            Spacer()
        }.overlay(alignment: .trailing) {
            Button {
                viewModel.checkAndCreateBook()
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
