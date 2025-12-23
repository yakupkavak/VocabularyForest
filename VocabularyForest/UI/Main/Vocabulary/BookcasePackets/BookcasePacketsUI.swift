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
                if let libraries = viewModel.libraries?.libraries, !libraries.isEmpty {
                    horizontalBookcaseList
                    verticalBookcaseList
                } else {
                    emptyView
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
                                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
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
                                    print("İndirilecek: \(library.name ?? "")")
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

struct CustomEmptyView: View {
    
    @State private var showEmptyText = false
    var emptyText: String

    var body: some View {
        VStack(spacing: 24){
            Spacer()
            tvDefault(text: emptyText, color: .brown300)
                .padding(24)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.title, lineWidth: 4)
                }.opacity(showEmptyText ? 1.0 : 0.0 )
            TalkingBallons(foregroundColor: .title, delayMultiplier: 1.5)
            LottieView(animation: .named("growingPlant"))
                .playing(loopMode: .playOnce).resizable().frame(maxWidth: 250).frame(maxHeight: 300)
            Spacer()
        }
        .onAppear {
            withAnimation(Animation.spring(duration: 1.0).delay(1.8)) {
                     self.showEmptyText = true
                }
        }.padding(.bottom, 32)
    }
}

struct BookcasePacketRow: View {
    
    // MARK: - PROPERTIES
    
    @State private var isShow = false
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    var language: String
    var libraries: [Library]
    var onClick: (Library) -> Void
    
    // MARK: - UI
    
    var body: some View {
        VStack {
            HStack {
                Text(language.toLanguageDisplayName()).foregroundStyle(.clickableButton)
                Image(systemName: isShow ? "chevron.up" : "chevron.down").foregroundStyle(.clickableButton)
            }.frame(maxWidth: .infinity).onTapGesture {
                isShow.toggle()
            }.padding(.bottom)
            
            if isShow {
                let width = UIScreen.main.bounds.width - (safeAreaInsets.leading + safeAreaInsets.trailing)
                HStack {
                    Text("Dil")
                        .frame(width: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                    
                    Text("Anlam")
                        .frame(width: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                    
                    Text("Kitaplık Adı")
                        .frame(maxWidth: width * 0.40, alignment: .center).foregroundStyle(.logoGreen)
                    
                    Text("İndir")
                        .frame(width: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                }
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                Divider().ignoresSafeArea()
                ForEach(libraries) { library in
                    if let source = library.sourceLanguage, let target = library.targetLanguage, let name = library.name {
                        HStack(alignment: .center) {
                            Text(source.toLanguageDisplayName())
                                .frame(width: width * 0.22, alignment: .trailing)
                            Text(target.toLanguageDisplayName())
                                .frame(width: width * 0.22, alignment: .center)
                            Text(name.capitalized)
                                .frame(width: width * 0.22, alignment: .center)
                            Button {
                                onClick(library)
                            } label: {
                                Image(systemName: "square.and.arrow.down").foregroundStyle(.clickableButton)
                            }
                            .frame(width: width * 0.2, alignment: .center)
                        }
                    }
                }

            }
        }.padding()
    }
}

struct BookcasePacketsUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(libraries: .mock))
                .previewDisplayName("Success State")
            
            // SENARYO 2: Veri Yok / Yükleniyor (Loading State)
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(libraries: nil))
                .previewDisplayName("Loading/Empty State")
            
            // SENARYO 3: Hata Durumu (Error State)
            BookcasePacketsUI(viewModel: MockBookcasePacketsViewModel(libraries: nil, error: "Sunucuya erişilemiyor."))
                .previewDisplayName("Error State")
        }
        // Eğer Router EnvironmentObject gerektiriyorsa buraya eklemeyi unutma:
        .environmentObject(BookcaseRouter())
    }
}
