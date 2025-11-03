//
//  EditBookUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

import SwiftUI
import Toasts
internal import CoreData

// MARK: - EDIT BOOK TYPE ENUM

enum EditBookToastType {
    case firstBookcaseCreated, newBookCreated, none
}


struct EditBookUI: View {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject private var createBookRouter: CreateBookRouter
    @Environment(\.presentToast) var presentToast
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = EditBookViewModel()
    @State private var showSelectBookcase = false
    @State private var selectedBookcase: BookcaseModel? = nil
    var book: Book
    
    // MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem
                            .ignoresSafeArea()
            VStack {
                defaultHeader
                textFields
                Spacer()
            }.frame(minHeight: 0, maxHeight: .infinity)
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
        }
    }
}

// MARK: - COMPONENTS

private extension EditBookUI {
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
                Text("Add").foregroundStyle(.title)
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

private extension EditBookUI {
    private func selectBookcase() {
        showSelectBookcase.toggle()
    }
    func createBookcase(){
        createBookRouter.navigate(to: .createBookcase)
    }
}

// MARK: - CONSTANTS

private extension EditBookUI {
    enum Field: Hashable {
        case vocabulary, meaning, sentence
        case description, bookcaseName
        case learningLanguage, meaningLanguage
    }
}

#Preview {
    let context = CoreDataManager.preview.viewContext
    let sampleBookcase = Bookcase(context: context)
    sampleBookcase.name = "Örnek Kitaplık (Preview)"
    sampleBookcase.createdDate = Date()
    sampleBookcase.learningLanguage = "ja"
    sampleBookcase.meaningLanguage = "tr"
    let sampleBook = Book(context: context)
    sampleBook.bookcase = sampleBookcase
    sampleBook.exampleSentence = "example"
    sampleBook.learningWord = "learning"
    sampleBook.descriptionWord = "description"
    sampleBook.longMemory = true
    
    return EditBookUI(book: sampleBook)
}
