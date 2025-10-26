//
//  BookcaseDetailUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 25.10.2025.
//

import SwiftUI
internal import CoreData

struct BookcaseDetailUI: View {
    
    // MARK: - PROPERTIES
    
    @State private var showMeaning = true
    @StateObject private var viewModel:  BookcaseDetailViewModel
    var bookcaseName: String
    
    // MARK: - INIT
    
    init(bookcaseName: String){
        self.bookcaseName = bookcaseName
        _viewModel = StateObject(wrappedValue: BookcaseDetailViewModel(bookcaseName: bookcaseName))
    }
    
    // MARK: - VIEWS

    var body: some View {
        List {
            ForEach(Array(viewModel.books.enumerated()), id: \.element) { index, book in
                bookRow(
                    book: book,
                    showMeaning: $showMeaning,
                    bookNumber: index + 1
                ).onAppear {
                    print(book)
                }
            }
            //.onDelete(perform: viewModel.deleteBook)
        }
        .navigationTitle(viewModel.bookcaseName)
        .toolbar {
            Toggle("Show Meaning", isOn: $showMeaning)
                .toggleStyle(.button)
        }
    }
}

private extension BookcaseDetailUI {
    @ViewBuilder
    func bookRow(book: Book, showMeaning: Binding<Bool>, bookNumber: Int) -> some View {
        VStack(alignment: .leading){
            HStack{
                tvHint(text: "\(bookNumber)")
                tvDefault(text: book.unwrappedLearningWord)
                Spacer()
            }
            tvDefault(text: book.unwrappedDescriptionWord)
            if showMeaning.wrappedValue{
                tvDefault(text: book.unwrappedMeaningWord)
                    .transition(.opacity.combined(with: .scale))
            }
            tvDefault(text: book.unwrappedMeaningWord)
        }.animation(.spring(response: 0.3, dampingFraction: 0.6), value: showMeaning.wrappedValue)
    }
}

#Preview {
    let context = CoreDataManager.preview.viewContext
    let sampleBookcase = Bookcase(context: context)
    sampleBookcase.name = "Örnek Kitaplık (Preview)"
    sampleBookcase.createdDate = Date()
    sampleBookcase.learningLanguage = "ja"
    sampleBookcase.meaningLanguage = "tr"
    
    return BookcaseDetailUI(bookcaseName: "sampleBookcase")
}
