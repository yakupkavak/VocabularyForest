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

// MARK: - CONSTANTS

private extension BookcaseDetailUI {
    enum Constant {
        static let frameWidth: CGFloat = 100
    }
}

struct BookcaseDetailUI: View {
    
    // MARK: - PROPERTIES
    
    @State private var showMeaning = false
    @State private var showEmptyText = false
    @StateObject private var viewModel: BookcaseDetailViewModel
    @FocusState private var searchBarIsFocused: Bool
    var bookcaseName: String
    
    // MARK: - INIT
    
    init(bookcaseName: String){
        self.bookcaseName = bookcaseName
        _viewModel = StateObject(wrappedValue: BookcaseDetailViewModel(bookcaseName: bookcaseName))
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
        .background(.backgroundSystem)
    }
}

// MARK: - VIEW BUILDER FUNCTIONS

private extension BookcaseDetailUI {
    @ViewBuilder
    func bookRow(book: Book, showMeaning: Binding<Bool>, bookNumber: Int) -> some View {
        VStack(alignment: .leading){
            HStack(alignment: .top){
                Text("\(book.bookcase?.unwrappedLearningLanguage.getCountryName() ?? "Learning")").frame(width: Constant.frameWidth, alignment: .leading)
                Text(":")
                tvDefault(text: book.unwrappedLearningWord)
                Spacer()
            }
            if showMeaning.wrappedValue{
                HStack(alignment: .top){
                    Text("\(book.bookcase?.unwrappedmeaningLanguage.getCountryName() ?? "Meaning")").frame(width: Constant.frameWidth, alignment: .leading)
                    Text(":")
                    tvDefault(text: book.unwrappedMeaningWord)
                    Spacer()
                }
            }
            if let description = book.descriptionWord {
                HStack(alignment: .top){
                    Text("Description").frame(width: Constant.frameWidth, alignment: .leading)
                    Text(":")
                    tvDefault(text: description)
                    Spacer()
                }
            }
            if let example = book.exampleSentence {
                HStack(alignment: .top){
                    Text("Example").frame(width: Constant.frameWidth, alignment: .leading)
                    Text(":")
                    tvDefault(text: example)
                    Spacer()
                }
            }
        }.animation(.spring(response: 0.3, dampingFraction: 0.6), value: showMeaning.wrappedValue)
            .frame(maxWidth: .greatestFiniteMagnitude)
            .padding()
            .borderRadius(borderColor: .unselectedButton)
            .padding()
            .background(.backgroundSystem)
            .overlay(alignment: .topTrailing, content: {
                Image(book.longMemory ? "longMemoryIcon" : "shortMemoryIcon").resizable().scaledToFit().frame(width: 24).offset(x: -24, y: 24)
            })
    }
}

// MARK: VIEW COMPONENTS

private extension BookcaseDetailUI {
    var header: some View {
        HStack{
            Button {
                onClickBookcaseIcon()
            } label: {
                Image("bookcase").resizable().scaledToFit().frame(maxWidth: 40)
            }
            CustomSearchBar(searchText: $viewModel.searchText, placeholder: "Search word").focused($searchBarIsFocused)
        }.padding(.horizontal,32)
    }
    var emptyBooks: some View {
        VStack(spacing: 24){
            Spacer()
            if showEmptyText {
                tvDefault(text: "We couldn't find any books", color: .brown300).padding(24)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.title, lineWidth: 4)
                    }
            }
            TalkingBallons(foregroundColor: .title, delayMultiplier: 1.0)
            LottieView(animation: .named("growingPlant"))
                .playing(loopMode: .playOnce).resizable().frame(maxWidth: 250).frame(maxHeight: 300)
        }.onAppear {
            withAnimation(Animation.spring(duration: 1.0).delay(1.2)) {
                     self.showEmptyText = true
                }
        }.padding(.bottom, 32)
    }
    var bookArray: some View {
        List {
            ForEach(Array(viewModel.books.enumerated()), id: \.element) { index, book in
                bookRow(
                    book: book,
                    showMeaning: $showMeaning,
                    bookNumber: index + 1
                ).onAppear {
                    print(book)
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden, edges: .all)
            }//.onDelete(perform: viewModel.deleteBook)
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}

// MARK: - HELPERS

private extension BookcaseDetailUI {
    func onClickBookcaseIcon() {
        
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
    
    return BookcaseDetailUI(bookcaseName: "sampleBookcase")
}
