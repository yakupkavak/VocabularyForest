//
//  CreateBootcaseUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import SwiftUI
import Lottie

struct CreateBookcaseUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject private var viewModel = CreateBookcaseViewModel()
    @FocusState private var focusedField: Field?
    @State private var activeSheet: SheetTypes? = nil

    // MARK: - VIEWS
    
    var body: some View {
        VStack() {
            initalizeUser
        }.sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .learning:
                SelectLanguageUI(selectedLanguage: $viewModel.learningLanguage)
            case .meaning:
                SelectLanguageUI(selectedLanguage: $viewModel.meaningLanguage)
            }
        }
        .background(.backgroundSystem)
        .navigationTitle("Create bookcase")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - VIEW COMPONENTS

private extension CreateBookcaseUI {
    var initalizeUser: some View {
        VStack(alignment: .leading ,spacing: 16) {
            tvDefault(text: "Bookcase name")
            VocabularyTextField(
                userInput: $viewModel.bookcaseName,
                isSelected: .constant(focusedField == .bookcaseName),
                isEmpty: $viewModel.emptyInitialBookcaseName,
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
            }.tint(Color.clickableButton).buttonStyle(.bordered)

            Spacer()
        }.padding(24)
    }
}

// MARK: - CONSTANTS

private extension CreateBookcaseUI {
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
    CreateBookcaseUI()
}
