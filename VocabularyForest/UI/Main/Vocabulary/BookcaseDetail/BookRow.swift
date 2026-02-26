//
//  BookRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 2.11.2025.
//

import SwiftUI

// MARK: - CONSTANTS

private extension BookRow {
    enum Constant {
        static let frameWidth: CGFloat = 100
    }
}

struct BookRow: View{
    
    // MARK: - PROPERTIES
    
    var book: BookModel
    var showMeaning: Binding<Bool>
    var bookNumber: Int
    var onEdit: () -> Void
    var onDelete: (BookModel) -> Void
    
    // MARK: - VIEW
    
    var body: some View {
        VStack(alignment: .leading){
            HStack(alignment: .top){
                Text("\(book.learningLanguageCode?.toLanguageDisplayName() ?? "Learning")").frame(width: Constant.frameWidth, alignment: .leading)
                Text(":")
                tvDefault(text: book.learningWord)
                Spacer()
            }
            if showMeaning.wrappedValue{
                HStack(alignment: .top){
                    Text("\(book.meaningLanguageCode?.toLanguageDisplayName() ?? "Meaning")").frame(width: Constant.frameWidth, alignment: .leading)
                    Text(":")
                    tvDefault(text: book.meaningWord)
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
        .padding(.vertical)
        .padding(.leading)
        .padding(.trailing, 12)
        .borderRadius(borderColor: .unselectedButton)
        .padding()
        .background(.backgroundSystem)
        .overlay(alignment: .topTrailing) {
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: {
                            onDelete(book)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
            } label: {
                Image("ellipsis_vertical")
                    .resizable().scaledToFit().frame(width: 32)
                    .padding(5)
                    .contentShape(Rectangle())
            }.offset(x: -12, y: 20)
        }
        .overlay(alignment: .bottomTrailing, content: {
            Image(book.longMemory ? "longMemoryIcon" : "shortMemoryIcon").resizable().scaledToFit().frame(width: 24).offset(x: -24, y: -24)
        }).background(.red)
    }
}
