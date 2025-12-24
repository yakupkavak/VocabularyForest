//
//  BookcasePacketsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.12.2025.
//

import SwiftUI
import Lottie

struct BookcasePacketsUI<ViewModel>: View where ViewModel: BookcasePacketsViewModelProtocol {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject private var router: BookcaseRouter
    @StateObject private var viewModel: ViewModel
    @State private var showEmpty = false
    
    // MARK: - INIT
    
    init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            Color.backgroundSystem.ignoresSafeArea()
            VStack {
                defaultHeader
                switch viewModel.uiState {
                case .success:
                    horizontalBookcaseList
                    verticalBookcaseList
                case .loading:
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .logoGreen))
                            .scaleEffect(1.5)
                        Text("Kitaplıklar Yükleniyor...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                case .empty:
                    emptyView
                case .error(let string):
                    CustomErrorView(emptyText: string)
                }
                Spacer()
            }
        }
    }
}

// MARK: - UI COMPONENTS

extension BookcasePacketsUI {
    var defaultHeader: some View {
        HStack {
            Spacer()
            Text("Hazır Kütüphaneler").font(.system(size: 24)).fontWeight(.medium).foregroundStyle(.title)
            Spacer()
        }.overlay(alignment: .leading) {
            Button {
                router.navigateBack()
            } label: {
                Image(systemName: "chevron.backward").resizable().scaledToFit().frame(width: 32).foregroundStyle(.clickableButton)
            }.offset(x: 32)
        }
    }
    
    var horizontalBookcaseList: some View {
        VStack {
            if let libraries = viewModel.libraries?.libraries {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let uniqueSourceLanguages = Array(Set(libraries.compactMap { $0.sourceLanguage })).sorted()
                        
                        ForEach(uniqueSourceLanguages, id: \.self) { languageCode in
                            
                            let isSelected = viewModel.selectedLibrary == languageCode
                            
                            Text(languageCode.toLanguageDisplayName())
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.brown700 : .brown300)
                                )
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.selectLibrary(code: languageCode)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
            }
        }
    }
    
    var verticalBookcaseList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if let libraries = viewModel.libraries?.libraries, let selected = viewModel.selectedLibrary {
                
                VStack(spacing: 0) {
                    let filteredBySource = libraries.filter { $0.sourceLanguage == selected }
                    let groupedLibraries = Dictionary(grouping: filteredBySource) { $0.targetLanguage ?? "Bilinmiyor" }
                    let sortedKeys = groupedLibraries.keys.sorted()
                    if sortedKeys.isEmpty {
                        Text("Bu dil için kütüphane bulunamadı.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(sortedKeys, id: \.self) { targetLangKey in
                            if let libsForTarget = groupedLibraries[targetLangKey] {
                                BookcasePacketRow(
                                    language: targetLangKey,
                                    libraries: libsForTarget
                                ) { library in
                                    viewModel.downloadLibrary(model: library)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var emptyView: some View {
        CustomEmptyView(emptyText: "Hiçbir kitaplık bulunamadı")
    }
}

struct BookcasePacketsUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(
                uiState: .success,
                libraries: .mock
            ))
            .previewDisplayName("1. Success State")
            
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(
                uiState: .loading,
                libraries: nil
            ))
            .previewDisplayName("2. Loading State")
            
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(
                uiState: .empty,
                libraries: nil
            ))
            .previewDisplayName("3. Empty State")
            
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(
                uiState: .error("İnternet bağlantısı koptu."),
                libraries: nil
            ))
            .previewDisplayName("4. Error State")
        }
        .environmentObject(BookcaseRouter())
    }
}
