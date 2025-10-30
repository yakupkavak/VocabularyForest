//
//  BookcaseFeedUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.10.2025.
//

import SwiftUI
internal import CoreData
import Lottie

struct BookcaseFeedUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject private var viewModel = BookcaseFeedViewModel()
    @EnvironmentObject private var bookcaseRouter: BookcaseRouter
    @State private var searchText = ""
    @State private var showEmptyText = false
    @FocusState private var searchBarIsFocused: Bool

    // MARK: - VIEWS
    
    var body: some View {
        VStack{
            header
            if viewModel.bookcases.isEmpty {
                emptyList
            }else {
                bookcaseList
            }
        }.background(.backgroundSystem)
            .ignoresSafeArea(.keyboard).onTapGesture {
                searchBarIsFocused = false
            }
    }
}

// MARK: - VIEW COMPONENTS

private extension BookcaseFeedUI {
    var header: some View {
        HStack{
            Button {
                onClickBookcaseIcon()
            } label: {
                Image("bookcase").resizable().scaledToFit().frame(maxWidth: 40)
            }
            CustomSearchBar(searchText: $searchText, placeholder: "Search bookcase").focused($searchBarIsFocused)
        }.padding(.horizontal,32)
    }
    var emptyList: some View {
        VStack(spacing: 24){
            Spacer()
            if showEmptyText {
                tvDefault(text: "We couldn't find any bookcase", color: .brown300).padding(24)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.title, lineWidth: 4)
                    }
            }
            TalkingBallons(foregroundColor: .title, delayMultiplier: 1.5)
            LottieView(animation: .named("growingPlant"))
                .playing(loopMode: .playOnce).resizable().frame(maxWidth: 250).frame(maxHeight: 300)
        }.onAppear {
            withAnimation(Animation.spring(duration: 1.0).delay(1.8)) {
                     self.showEmptyText = true
                }
        }.padding(.bottom, 32)
    }
    var bookcaseList: some View {
        List{
            ForEach(viewModel.bookcases, id: \.self) { bookcase in
                BookcaseRow(bookcase: bookcase, animalModel: getRandomAnimalModel()).onTapGesture {
                    bookcaseRouter.navigate(to: .bookcaseDetail(bookcase: bookcase.unwrappedName))
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden, edges: .all)
            }.onDelete { indexSet in
                viewModel.deleteBookcase(indexSet: indexSet)
            }
        }.scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
    }
}

// MARK: - HELPERS

private extension BookcaseFeedUI {
    func onClickBookcaseIcon() {
        bookcaseRouter.navigate(to: .createBookcase)
    }
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
