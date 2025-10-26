//
//  BookcaseRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import SwiftUI

struct BookcaseRow: View {
    
    // MARK: - PROPERTIES
    
    let bookcase: Bookcase
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 20){
            HStack{
                tvSubtitle(text: bookcase.unwrappedName)
                Spacer()
                Button {
                    print("update book")
                } label: {
                    Image(systemName: "heart.fill").resizable().scaledToFit().frame(width: 24)
                }.buttonStyle(.plain)

            }
            HStack{
                tvHint(text: " \(bookcase.unwrappedLearningLanguage) - \(bookcase.unwrappedmeaningLanguage)")
                Spacer()
                tvDefault(text: "10/100")
            }
        }.padding().background(.red).clipShape(RoundedRectangle(cornerRadius: 20))

    }
}
