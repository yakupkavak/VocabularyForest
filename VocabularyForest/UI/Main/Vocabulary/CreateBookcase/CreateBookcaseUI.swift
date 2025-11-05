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
        .navigationTitle("Kitaplık oluştur")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - VIEW COMPONENTS

private extension CreateBookcaseUI {
    var initalizeUser: some View {
        VStack(alignment: .leading ,spacing: 16) {
            tvDefault(text: "Kitaplık adı")
            VocabularyTextField(
                userInput: $viewModel.bookcaseName,
                isSelected: .constant(focusedField == .bookcaseName),
                isEmpty: $viewModel.emptyInitialBookcaseName,
                placeholder: "Günlük kelimeler, hobiler vs.",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .bookcaseName)
            tvDefault(text: "Öğrendiğin dil")
            Button(action: {
                activeSheet = .learning
            }) {
                LanguageRowUI(
                    isEmpty: $viewModel.emptyInitialVocabularyLanguage,
                    language: viewModel.learningLanguage,
                    placeholder: "Öğrendiğin dili seç"
                )
            }.buttonStyle(.plain)
            tvDefault(text: "Anlamının dili")
            Button(action: {
                activeSheet = .meaning
            }) {
                LanguageRowUI(
                    isEmpty: $viewModel.emptyInitialMeaningLanguage,
                    language: viewModel.meaningLanguage,
                    placeholder: "Anlam dilini seçin"
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
                Text("Oluştur").padding(.vertical, 8).padding(.horizontal, 4).frame(maxWidth: .greatestFiniteMagnitude, alignment: .center)
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
