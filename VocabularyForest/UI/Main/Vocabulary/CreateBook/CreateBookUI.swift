//
//  FeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import Toasts

// MARK: - CREATE BOOK TYPE ENUM

enum CreateBookToastType {
    case firstBookcaseCreated, newBookCreated, none
}

struct CreateBookUI: View {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject private var createBookRouter: CreateBookRouter
    @Environment(\.presentToast) var presentToast
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = CreateBookViewModel()
    @State private var showSelectBookcase = false
    @State private var selectedBookcase: BookcaseModel? = nil

    // MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem
                            .ignoresSafeArea()
            VStack {
                if viewModel.bookcasesList.isEmpty {
                    CreateBookcaseUI()
                }else {
                    defaultHeader
                    textFields
                }
                Spacer()
            }.frame(minHeight: 0, maxHeight: .infinity).sheet(isPresented: $showSelectBookcase) {
                SelectBookcaseUI(allBookcases: viewModel.bookcasesList, selectedBookcase: $selectedBookcase)
            }
            .addToastSafeAreaObserver()
            .onChange(of: selectedBookcase) { selectedBookcaseModel in
                if let selectedBookcaseModel {
                    viewModel.fetchBookWithModel(bookcaseModel: selectedBookcaseModel)
                }
            }.onChange(of: viewModel.toastMessageModel) { model in
                switch model {
                case .firstBookcaseCreated:
                    presentToast(ToastValue(message: "Congratulations!"))
                case .newBookCreated:
                    presentToast(ToastValue(message: "Book created!"))
                case .none:
                    print("none create book")
                }
            }.onAppear {
                viewModel.fetchBookcases()
            }
        }.onSubmit {
            if let focusedField {
                switch focusedField {
                case .vocabulary:
                    self.focusedField = .meaning
                case .meaning:
                    self.focusedField = .description
                case .description:
                    self.focusedField = .sentence
                case .sentence:
                    viewModel.checkAndCreateBook()
                    hideKeyboard()
                }
            }
        }.onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - COMPONENTS

private extension CreateBookUI {
    var textFields: some View {
        VStack(spacing: 20) {
            VocabularyTextField(
                userInput: $viewModel.bookLearningWord,
                isSelected: .constant(focusedField == .vocabulary),
                isEmpty: $viewModel.emptyBookLearningWord,
                placeholder: "Hangi kelimeyi öğreniyorsun (Gerekli)",
                title: viewModel.learningLanguage?.name,
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .vocabulary).submitLabel(.next)
            
            VocabularyTextField(
                userInput: $viewModel.bookMeaningWord,
                isSelected: .constant(focusedField == .meaning),
                isEmpty: $viewModel.emptyBookMeaningWord,
                placeholder: "Anlamı nedir (Gerekli)",
                title: viewModel.meaningLanguage?.localizedName
            ).focused($focusedField, equals: .meaning).submitLabel(.next)
            
            VocabularyTextField(
                userInput: $viewModel.bookDescription,
                isSelected: .constant(focusedField == .description),
                isEmpty: .constant(false),
                placeholder: "Açıklaması",
                title: "Açıklama",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            ).focused($focusedField, equals: .description).submitLabel(.next)
            
            VocabularyTextField(
                userInput: $viewModel.bookExampleSentence,
                isSelected: .constant(focusedField == .sentence),
                isEmpty: .constant(false),
                placeholder: "Örnek cümle",
                title: "Cümle"
            ).focused($focusedField, equals: .sentence).submitLabel(.done)
        }.padding(24)
    }
    var defaultHeader: some View {
        HStack{
            Spacer()
            VStack{
                Button {
                    selectBookcase()
                } label: {
                    tvTitle(text: viewModel.currentBookcase?.unwrappedName ?? "Unexpected error")
                }.foregroundStyle(.clickableButton).frame(maxWidth: 200)
            }
            Spacer()
        }.overlay(alignment: .trailing) {
            Button {
                viewModel.checkAndCreateBook()
            } label: {
                Text("Ekle").foregroundStyle(.title)
            }.offset(x: -24)
        }
        .overlay(alignment: .leading) {
            Button {
                print("Boockase")
            } label: {
                Button {
                    createBookcase()
                } label: {
                    Image("bookcase").resizable().scaledToFit().frame(minWidth: 20, maxWidth: 34)
                }
                
            }.offset(x: 24)
        }
    }
}

// MARK: - HELPERS

private extension CreateBookUI {
    private func selectBookcase() {
        showSelectBookcase.toggle()
    }
    func createBookcase(){
        createBookRouter.navigate(to: .createBookcase)
    }
}

// MARK: - CONSTANTS

private extension CreateBookUI {
    enum Field: Hashable {
        case vocabulary, meaning
        case description, sentence
    }
}

#Preview {
    CreateBookUI()
}
