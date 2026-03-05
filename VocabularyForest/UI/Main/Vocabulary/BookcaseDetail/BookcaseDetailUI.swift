//
//  BookcaseDetailUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.10.2025.
//

import SwiftUI
internal import CoreData
import Lottie

// TODO: - DELEGATE AND PROTOCOL ILE HABERLEŞME

struct BookcaseDetailUI: View {
    
    // MARK: - PROPERTIES
    
    @State private var showMeaning = false
    @State private var showEmptyText = false
    @StateObject private var viewModel: BookcaseDetailViewModel
    @FocusState private var searchBarIsFocused: Bool
    var bookcaseName: String
    var bookcaseLearningCode: String
    var bookcaseMeaningCode: String

    // MARK: - INIT
    
    init(bookcaseName: String, bookcaseLearningCode: String, bookcaseMeaningCode: String){
        self.bookcaseName = bookcaseName
        self.bookcaseLearningCode = bookcaseLearningCode
        self.bookcaseMeaningCode = bookcaseMeaningCode
        _viewModel = StateObject(wrappedValue: BookcaseDetailViewModel(bookcaseName: bookcaseName, learningLanguage: bookcaseLearningCode, meaningLanguage: bookcaseMeaningCode))
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.title]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.title]
    }
    
    // MARK: - VIEWS

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.createdAnyBook {
                header
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if viewModel.books.isEmpty {
                emptyBooks.onDisappear {
                    showEmptyText = false
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                bookArray
                    .transition(.opacity)
            }
        }.padding(.top, 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.createdAnyBook)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.books.isEmpty)
        .navigationTitle(viewModel.bookcaseName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMeaning.toggle()
                } label: {
                    Image(showMeaning ? "showEye" : "hideEye").resizable().scaledToFit().frame(maxWidth: 32).foregroundStyle(.brown300)
                }
            }
        }
        .frame(maxWidth: .greatestFiniteMagnitude)
        .background(
            Color.backgroundSystem
                .ignoresSafeArea()
                .onTapGesture {
                    searchBarIsFocused = false
                }
        )
        .sheet(item: $viewModel.editingBook) { bookToEdit in
            BookEditSheet(book: bookToEdit, onSave: { (learning, meaning, desc, example) in
                viewModel.updateBook(
                    bookToUpdate: bookToEdit,
                    learningWord: learning,
                    meaningWord: meaning,
                    descriptionWord: desc,
                    exampleSentence: example
                )
            })
        }
    }
}

// MARK: - VIEW BUILDER FUNCTIONS


// MARK: VIEW COMPONENTS

private extension BookcaseDetailUI {
    var header: some View {
        HStack{
            Button {
                onClickBookcaseIcon()
            } label: {
                Image("bookcase").resizable().scaledToFit().frame(maxWidth: 40)
            }
            CustomSearchBar(searchText: $viewModel.searchText, placeholder: String(localized: "Kelime ara")).focused($searchBarIsFocused)
        }.padding(.horizontal,32)
    }
    var emptyBooks: some View {
        VStack(spacing: 24){
            Spacer()
            if showEmptyText {
                tvDefault(text: String(localized: "Hiçbir kitap bulamadık"), color: .brown300).padding(24)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.title, lineWidth: 4)
                    }
            }
            TalkingBallons(foregroundColor: .title, delayMultiplier: 1.0)
            HStack{
                Spacer()
                LottieView(animation: .named("growingPlant"))
                    .playing(loopMode: .playOnce).resizable()
                Spacer()
            }
            Spacer()
        }.onAppear {
            withAnimation(Animation.spring(duration: 1.0).delay(1.2)) {
                     self.showEmptyText = true
                }
        }.padding(.bottom, 32)
    }
    var bookArray: some View {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.books.enumerated()), id: \.element) { index, book in
                        BookRow(
                            book: book,
                            showMeaning: $showMeaning,
                            bookNumber: index + 1,
                            onEdit: {
                                bookRowEdit(book: book)
                            },
                            onDelete: { book in bookRowDelete(book: book) }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
}

// MARK: - HELPERS

private extension BookcaseDetailUI {
    func onClickBookcaseIcon() {
        
    }
    func bookRowEdit(book: BookModel){
        viewModel.prepareForEdit(book: book)
    }
    func bookRowDelete(book: BookModel){
        viewModel.deleteBookModel(at: book)
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
    sampleBook.meaningWord = "meaning"
    sampleBook.learningWord = "learning"
    sampleBook.descriptionWord = "descr"
    sampleBook.exampleSentence = "sentence"
    sampleBook.bookcase = sampleBookcase
    
    return BookcaseDetailUI(bookcaseName: "sample", bookcaseLearningCode: "ja", bookcaseMeaningCode: "tr")
}
