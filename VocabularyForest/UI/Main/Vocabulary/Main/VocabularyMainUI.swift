//
//  FeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

struct VocabularyMainUI: View {
    
    //MARK: - PROPERTIES

    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = VocabularyMainViewModel()
    
    //MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem
                            .ignoresSafeArea()
            VStack {
                if viewModel.bookcasesList.isEmpty {
                    CreateBootcaseUI()
                }else {
                    defaultHeader
                    textFields
                }
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
