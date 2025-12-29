//
//  BookcasePacketRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.12.2025.
//

import SwiftUI

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
                    Text("Dili")
                        .frame(width: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                    
                    Text("Anlamı")
                        .frame(width: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                    
                    Text("Kitaplık Adı")
                        .frame(maxWidth: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                    Text("Kelime Sayısı")
                        .frame(maxWidth: width * 0.2, alignment: .center).foregroundStyle(.logoGreen)
                    Text("İndir")
                        .frame(width: width * 0.1, alignment: .center).foregroundStyle(.logoGreen)
                }
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                Divider().ignoresSafeArea()
                ForEach(libraries) { library in
                    if let source = library.sourceLanguage, let target = library.targetLanguage, let name = library.name, let count = library.wordCount {
                        HStack(alignment: .center) {
                            Text(source.toLanguageDisplayName())
                                .frame(width: width * 0.22, alignment: .center)
                            Text(target.toLanguageDisplayName())
                                .frame(width: width * 0.22, alignment: .leading)
                            Text(name.capitalized)
                                .frame(width: width * 0.15, alignment: .leading)
                            Text("\(count)")
                                .frame(width: width * 0.1, alignment: .center)
                            Button {
                                onClick(library)
                            } label: {
                                Image(systemName: "square.and.arrow.down").foregroundStyle(.clickableButton)
                            }
                            .frame(width: width * 0.1, alignment: .trailing)
                        }.padding(.bottom)
                    }
                }

            }
        }.padding()
    }
}
