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
    
    @ObservedObject var viewModel: BookcaseFeedViewModel
    @EnvironmentObject private var bookcaseRouter: BookcaseRouter
    @State private var showEmptyText = false
    @FocusState private var searchBarIsFocused: Bool
    
    // MARK: - VIEWS
    
    var body: some View {
        ZStack {
            Color.backgroundSystem
                .ignoresSafeArea()
                .onTapGesture {
                    searchBarIsFocused = false
                }
            VStack(spacing: 0) {
                if viewModel.createdAnyBookcase {
                    header
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if viewModel.bookcases.isEmpty {
                    noneDataView
                } else {
                    bookcaseList
                        .transition(.opacity)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.createdAnyBookcase)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.bookcases.isEmpty)
        .onAppear {
            viewModel.fetchBookcases()
        }
        .sheet(item: $viewModel.editingBookcaseItem) { item in
            BookcaseEditSheet(item: item) { (newName, newLearningLang, newMeaningLang) in
                viewModel.updateBookcase(
                    item: item,
                    newName: newName,
                    learningLang: newLearningLang,
                    meaningLang: newMeaningLang
                )
            }
        }
    }
}

// MARK: - VIEW COMPONENTS

private extension BookcaseFeedUI {
    var header: some View {
        HStack(alignment: .center){
            Button {
                bookcaseRouter.navigate(to: .bookcasePacket)
            } label: {
                Image("books (1)").resizable().scaledToFit().frame(maxWidth: 40).foregroundStyle(.clickableButton)
            }
            .accessibilityLabel(String(localized: "Hazır kütüphaneler"))
            CustomSearchBar(searchText: $viewModel.searchText, placeholder: String(localized: "Kitaplık ara")).focused($searchBarIsFocused)
            Button {
                bookcaseRouter.navigate(to: .createBookcase)
            } label: {
                Image(systemName: "plus").resizable().scaledToFit().frame(maxWidth: 28).foregroundStyle(.clickableButton)
            }
            .accessibilityLabel(String(localized: "Kitaplık oluştur"))
        }.padding(.horizontal,32)
    }
    var noneDataView: some View {
        VStack(spacing: 24){
            Spacer()
            Spacer()
            tvDefault(text: String(localized: "Hiçbir kitaplık bulamadık"), color: .brown300)
                .padding(24)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.title, lineWidth: 4)
                }.opacity(showEmptyText ? 1.0 : 0.0 )
            TalkingBallons(foregroundColor: .title, delayMultiplier: 1.5)
            LottieView(animation: .named("growingPlant"))
                .playing(loopMode: .playOnce).resizable().frame(maxWidth: 250).frame(maxHeight: 300)
            Button {
                bookcaseRouter.navigate(to: .bookcasePacket)
            } label: {
                Text("Hazır kütüphaneler").padding().background(Color.clickableButton).foregroundStyle(.white).font(.system(size: 20)).borderRadius(borderColor: .clickableButton)
            }.buttonStyle(.plain)
            Button {
                bookcaseRouter.navigate(to: .createBookcase)
            } label: {
                Text("Kitaplık oluştur").padding().background(Color.clickableButton).foregroundStyle(.white).font(.system(size: 20)).borderRadius(borderColor: .clickableButton)
            }
            Spacer()

        }
        .onAppear {
            withAnimation(Animation.spring(duration: 1.0).delay(1.8)) {
                     self.showEmptyText = true
                }
        }.padding(.bottom, 32)
    }
    var bookcaseList: some View {
        List{
            ForEach(viewModel.bookcases, id: \.id) { bookcaseDisplayItem in
                BookcaseRow(bookcase: bookcaseDisplayItem.bookcase, animalModel: bookcaseDisplayItem.animalModel, onEdit: {
                    viewModel.prepareForEdit(item: bookcaseDisplayItem)
                }, onDelete: {
                    viewModel.deleteBookcase(item: bookcaseDisplayItem)
                })
                .contentShape(Rectangle())
                .onTapGesture {
                    bookcaseRouter.navigate(
                        to: .bookcaseDetail(bookcase: bookcaseDisplayItem.bookcase.bookcaseName, learning: bookcaseDisplayItem.bookcase.learningLanguage,meaning: bookcaseDisplayItem.bookcase.meaningLanguage)
                    )
                }
                .a11yTapButton(hint: String(localized: "a11y_open_bookcase_hint"))
                .accessibilityAction(named: Text("Düzenle")) {
                    viewModel.prepareForEdit(item: bookcaseDisplayItem)
                }
                .accessibilityAction(named: Text("Sil")) {
                    viewModel.deleteBookcase(item: bookcaseDisplayItem)
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden, edges: .all)
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
    let mockViewModel: BookcaseFeedViewModel = {
        let previewManager = CoreDataManager.preview
        let context = previewManager.viewContext
        
        let sampleBookcase = Bookcase(context: context)
        sampleBookcase.name = "Japonca A1 Kelimeler"
        sampleBookcase.learningLanguage = "ja"
        sampleBookcase.meaningLanguage = "tr"
        sampleBookcase.createdDate = Date()
        
        try? context.save()
        
        return BookcaseFeedViewModel(coreDataManager: previewManager)
    }()
    
    NavigationStack {
        BookcaseFeedUI(viewModel: mockViewModel)
            .environmentObject(BookcaseRouter())
    }
}
