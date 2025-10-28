//
//  BookcaseFeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import SwiftUI
internal import CoreData

struct BookcaseFeedUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject private var viewModel = BookcaseFeedViewModel()
    @EnvironmentObject private var bookcaseRouter: BookcaseRouter
    
    // MARK: - VIEWS

    var body: some View {
        VStack{
            List{
                ForEach(viewModel.bookcases, id: \.self) { bookcase in
                    BookcaseRow(bookcase: bookcase).onTapGesture {
                        bookcaseRouter.navigate(to: .bookcaseDetail(bookcase: bookcase.unwrappedName))
                    }
                }.onDelete { indexSet in
                    viewModel.deleteBookcase(indexSet: indexSet)
                }
            }
        }
    }
    
}

// MARK: - VIEW COMPONENTS

private extension BookcaseFeedUI {

}

#Preview {
    let context = CoreDataManager.preview.viewContext
    let sampleBookcase = Bookcase(context: context)
    sampleBookcase.name = "Örnek Kitaplık (Preview)"
    sampleBookcase.createdDate = Date()
    sampleBookcase.learningLanguage = "ja"
    sampleBookcase.meaningLanguage = "tr"

    return BookcaseFeedUI()
}
