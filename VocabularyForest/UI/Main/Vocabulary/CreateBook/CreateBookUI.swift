//
//  FeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

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
    @Environment(\.presentToast) var presentToast
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = CreateBookViewModel()
    @State private var showSelectBookcase = false
    @State private var selectedBookcase: BookcaseModel? = nil

    // MARK: - VIEWS

    var body: some View {
        ZStack {
            Color.backgroundSystem.ignoresSafeArea()
            VStack {
                if viewModel.bookcasesList.isEmpty {
                    CreateBookcaseUI()
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
                    presentToast(ToastValue(message: "Tebrikler!"))
                case .newBookCreated:
                    presentToast(ToastValue(message: "Kitap oluşturuldu!"))
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
                .fixedSize()
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
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
                placeholder: "Hangi kelimeyi öğreniyorsun (Gerekli)",
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
                placeholder: "Anlamı nedir (Gerekli)",
                title: viewModel.meaningLanguage?.localizedName
            )
            .focused($focusedField, equals: .meaning)
            .submitLabel(.next)

            VocabularyTextField(
                userInput: $viewModel.bookDescription,
                isSelected: .constant(focusedField == .description),
                isEmpty: .constant(false),
                placeholder: "Açıklaması (\(viewModel.learningLanguage?.name.split(separator: " ").first ?? ""))",
                title: "Açıklama",
                imageHead: "elephanthead",
                imageFoot: "elephantfoot"
            )
            .focused($focusedField, equals: .description)
            .submitLabel(.next)

            VocabularyTextField(
                userInput: $viewModel.bookExampleSentence,
                isSelected: .constant(focusedField == .sentence),
                isEmpty: .constant(false),
                placeholder: "Örnek cümle (\(viewModel.learningLanguage?.name.split(separator: " ").first ?? ""))",
                title: "Cümle"
            )
            .focused($focusedField, equals: .sentence)
            .submitLabel(.done)
            
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
                    Text(viewModel.currentBookcase?.unwrappedName ?? "Unexpected error")
                        .font(.system(size: 20, weight: .bold))
                }
                .frame(maxWidth: 200)
                Text(
                    "\(viewModel.currentBookcase?.unwrappedLearningLanguage.toLanguageDisplayName() ?? "") - \(viewModel.currentBookcase?.unwrappedmeaningLanguage.toLanguageDisplayName() ?? "")"
                ) .font(.system(size: 14, weight: .medium))
            }
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                viewModel.checkAndCreateBook()
            } label: {
                Text("Ekle").foregroundStyle(.title)
            }
            .offset(x: -24)
        }
        .overlay(alignment: .leading) {
            Button {
                selectBookcase()
            } label: {
                Image("bookcase")
                    .resizable()
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

#Preview {
    CreateBookUI()
}
