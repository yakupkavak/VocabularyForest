//
//  FeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI
import DTO
import DependencyContainer

// MARK: - CREATE BOOK TYPE ENUM

enum CreateBookToastType {
    case firstBookcaseCreated, newBookCreated, none
}

// MARK: - CONSTANTS

private extension CreateBookUI {
    enum Constant {
        static let padding = CGFloat(10)
    }
}

struct CreateBookUI: View {

    // MARK: - PROPERTIES

    @EnvironmentObject private var createBookRouter: CreateBookRouter
    @EnvironmentObject private var coordinator: VocabularyForestCoordinator
    @Environment(\.presentToast) var presentToast
    @FocusState private var focusedField: Field?
    @ObservedObject var viewModel: CreateBookViewModel
    @State private var showSelectBookcase = false
    @State private var selectedBookcase: BookcaseModel? = nil

    // MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem.ignoresSafeArea()
            VStack {
                if viewModel.bookcasesList.isEmpty {
                    coordinator.startCreateBookcaseUI()
                } else {
                    defaultHeader
                    ScrollView(.vertical, showsIndicators: false) {
                        textFields
                    }
                }
                Spacer()
            }
            .frame(minHeight: 0, maxHeight: .infinity)
            .sheet(isPresented: $showSelectBookcase) {
                SelectBookcaseUI(allBookcases: viewModel.bookcasesList, selectedBookcase: $selectedBookcase)
            }
            .addToastSafeAreaObserver()
            .onChange(of: selectedBookcase) { selectedBookcaseModel in
                if let selectedBookcaseModel {
                    viewModel.fetchBookWithModel(bookcaseModel: selectedBookcaseModel)
                }
            }
            .onChange(of: viewModel.toastMessageModel) { model in
                switch model {
                case .firstBookcaseCreated:
                    presentToast(ToastValue(message: String(localized: "Tebrikler!")))
                case .newBookCreated:
                    presentToast(ToastValue(message: String(localized: "Kitap oluşturuldu!")))
                case .none:
                    break
                }
            }
            .onAppear {
                viewModel.fetchBookcases()
            }
        }
        .onSubmit {
            if let focusedField {
                switch focusedField {
                case .vocabulary:
                    self.focusedField = .meaning
                case .meaning:
                    self.focusedField = .description
                case .description:
                    self.focusedField = .sentence
                case .sentence:
                    self.focusedField = .partOfSpeech
                    hideKeyboard()
                case .partOfSpeech:
                    viewModel.checkAndCreateBook()
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .trackScreen(.createBook)
    }
}

// MARK: - COMPONENTS

struct PartOfSpeechTag: View {
    let partOfSpeech: PartOfSpeech
    @Binding var isSelected: Bool

    var body: some View {
        Button {
            withAnimation {
                isSelected.toggle()
            }
        } label: {
            Text(partOfSpeech.localizedText)
                .font(.system(size: 14))
                .fixedSize()
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .background(partOfSpeech.pasterColor).cornerRadius(16)
            .opacity(isSelected ? 1.0 : 0.6).padding(6)
    }
}

private extension CreateBookUI {
    var textFields: some View {
        VStack(spacing: 20) {
            VocabularyTextField(
                userInput: $viewModel.bookLearningWord,
                isSelected: .constant(focusedField == .vocabulary),
                isEmpty: $viewModel.emptyBookLearningWord,
                placeholder: String(localized: "Hangi kelimeyi öğreniyorsun (Gerekli)"),
                title: viewModel.learningLanguage?.name,
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            )
            .focused($focusedField, equals: .vocabulary)
            .submitLabel(.next)

            VocabularyTextField(
                userInput: $viewModel.bookMeaningWord,
                isSelected: .constant(focusedField == .meaning),
                isEmpty: $viewModel.emptyBookMeaningWord,
                placeholder: String(localized: "Anlamı nedir (Gerekli)"),
                title: viewModel.meaningLanguage?.localizedName
            )
            .focused($focusedField, equals: .meaning)
            .submitLabel(.next)
            
            let languageName = viewModel.learningLanguage?.name.split(separator: " ").first ?? ""
            VocabularyTextField(
                userInput: $viewModel.bookDescription,
                isSelected: .constant(focusedField == .description),
                isEmpty: .constant(false),
                placeholder: String(localized: "Description (\(languageName))"),
                title: String(localized: "Description"),
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            )
            .focused($focusedField, equals: .description)
            .submitLabel(.next)

            VocabularyTextField(
                userInput: $viewModel.bookExampleSentence,
                isSelected: .constant(focusedField == .sentence),
                isEmpty: .constant(false),
                placeholder: String(localized: "Örnek Cümle (\(languageName))"),
                title: String(localized: "Cümle")
            )
            .focused($focusedField, equals: .sentence)
            .submitLabel(.done)
            
            Button {
                if let url = URL(string: "https://dictionary.cambridge.org/") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Cambridge Dictionary").frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing).foregroundStyle(.clickableButton).font(.system(size: 14))
            }.padding(.vertical, -8)
            
            partOfSpeechPicker
                .focused($focusedField, equals: .partOfSpeech)

        }
        .padding(24)
    }

    var partOfSpeechPicker: some View {
        FlowLayout {
            ForEach(partOfSpeechList) { part in
                PartOfSpeechTag(partOfSpeech: part, isSelected: Binding(get: {viewModel.partOfSpeech == part}, set: { isSelected in
                    if isSelected {
                        viewModel.selectTag(model: part)
                    }}))
            }
        }
    }

    var defaultHeader: some View {
        HStack {
            Spacer()
            VStack {
                Button {
                    selectBookcase()
                } label: {
                    Text(viewModel.currentBookcase?.bookcaseName ?? String(localized: "Kitaplık seçilmedi"))
                        .font(.system(size: 20, weight: .bold))
                }
                .frame(maxWidth: 200)
                Text(
                    "\(viewModel.currentBookcase?.learningLanguage.toLanguageDisplayName() ?? "") - \(viewModel.currentBookcase?.meaningLanguage.toLanguageDisplayName() ?? "")"
                ) .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.brown300)
            }
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                viewModel.checkAndCreateBook()
                focusedField = .vocabulary
            } label: {
                Text("Ekle").foregroundStyle(.darkGren)
            }
            .offset(x: -24)
        }
        .overlay(alignment: .leading) {
            Button {
                selectBookcase()
            } label: {
                Image("bookcase")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.brown300)
                    .scaledToFit()
                    .frame(minWidth: 24, maxWidth: 36)
            }
            .offset(x: 24)
        }
    }
}

// MARK: - HELPERS

private extension CreateBookUI {
    private func selectBookcase() {
        showSelectBookcase.toggle()
    }
}

// MARK: - CONSTANTS

private extension CreateBookUI {
    enum Field: Hashable {
        case vocabulary, meaning, description, partOfSpeech, sentence
    }
}
