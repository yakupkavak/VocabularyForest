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
    
    @EnvironmentObject private var router: BookcaseRouter
    @ObservedObject var viewModel: CreateBookcaseViewModel
    @FocusState private var focusedField: Field?
    @State private var activeSheet: SheetTypes? = nil
    /// When set, called after a successful creation instead of the default router navigation (e.g. when shown inside a sheet)
    var onCreated: (() -> Void)? = nil
    
    // MARK: - VIEWS
    
    var body: some View {
        VStack() {
            initalizeUser
        }.sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .learning:
                SelectLanguageUI(selectedLanguage: $viewModel.learningLanguage, dismissLanguage: $viewModel.meaningLanguage)
            case .meaning:
                SelectLanguageUI(selectedLanguage: $viewModel.meaningLanguage, dismissLanguage: $viewModel.learningLanguage)
            }
        }
        .background(.backgroundSystem)
        .navigationTitle("Kitaplık oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen(.createBookcase)
    }
}

// MARK: - VIEW COMPONENTS

private extension CreateBookcaseUI {
    var initalizeUser: some View {
        VStack(alignment: .leading ,spacing: 16) {
            tvDefault(text: String(localized: "Kitaplık adı"))
            VocabularyTextField(
                userInput: $viewModel.bookcaseName,
                isSelected: .constant(focusedField == .bookcaseName),
                isEmpty: $viewModel.emptyInitialBookcaseName,
                placeholder: String(localized: "Günlük kelimeler, hobiler vs."),
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .bookcaseName).frame(minHeight: 80)
            tvDefault(text: String(localized: "Öğrendiğin dil"))
            Button(action: {
                activeSheet = .learning
            }) {
                LanguageRowUI(
                    isEmpty: $viewModel.emptyInitialVocabularyLanguage,
                    language: viewModel.learningLanguage,
                    placeholder: String(localized: "Öğrendiğin dili seç")
                )
            }.buttonStyle(.plain)
            tvDefault(text: String(localized: "Anlamının dili"))
            Button(action: {
                activeSheet = .meaning
            }) {
                LanguageRowUI(
                    isEmpty: $viewModel.emptyInitialMeaningLanguage,
                    language: viewModel.meaningLanguage,
                    placeholder: String(localized: "Anlam dilini seçin")
                )
            }.buttonStyle(.plain)
            HStack{
                Spacer()
                LottieView(animation: .named("meditationSloth"))
                    .playing(loopMode: .loop).resizable().frame(maxWidth: 250)
                    .a11yDecorative()
                Spacer()
            }
            Button {
                if viewModel.checkAndCreateBookcase() {
                    if let onCreated {
                        onCreated()
                    } else {
                        router.navigateToRoot()
                    }
                }
            } label: {
                Text("Oluştur").padding(.vertical, 8).padding(.horizontal, 4).frame(maxWidth: .greatestFiniteMagnitude, alignment: .center)
            }.tint(Color.brown300).buttonStyle(.borderedProminent)

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
    CreateBookcaseUI(viewModel: CreateBookcaseViewModel(coreDataManager: CoreDataManager(), analyticsService: NoopAnalyticsService()))
}
