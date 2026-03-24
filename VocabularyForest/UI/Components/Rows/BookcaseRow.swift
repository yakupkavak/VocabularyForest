//
//  BookcaseRow.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.10.2025.
//

import SwiftUI
import CoreData
import DTO

struct BookcaseRow: View {
    
    // MARK: - PROPERTIES
    
    var bookcase: BookcaseModel
    var animalModel: AnimalBodyModel
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 20){
            topLine
            languageLine
            bottomLine
        }.padding().borderRadius(borderColor: .gray).padding().overlay(alignment: .bottomTrailing) {
            if let longCount = bookcase.longMemoryBooksCount, let totalCount = bookcase.totalBooksCount, longCount > 0 {
                MemoryProgressBar(percentage: Int(Double(longCount) / Double(totalCount) * 100), width: 45).offset(x: -32, y: -32)
            }else {
                MemoryProgressBar(percentage: 0, width: 45).offset(x: -32, y: -32)
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(animalModel.head)
                .resizable().scaledToFit().frame(width: 40)
                .offset(x: -30,y: 0)
        }
        .background(.backgroundSystem)
    }
}

// MARK: - UI COMPONENTS

private extension BookcaseRow {
    var topLine: some View {
        HStack{
            tvSubtitle(text: bookcase.bookcaseName)
            Spacer()
            Menu {
                Button(action: onEdit) {
                    Label("Düzenle", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Sil", systemImage: "trash")
                }
            } label: {
                Image("ellipsis_vertical")
                    .resizable().scaledToFit().frame(width: 32)
                    .padding(5)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    var languageLine: some View {
        HStack{
            tvGrayHint(text: "\(bookcase.learningLanguage.toLanguageDisplayName()) / \(bookcase.meaningLanguage.toLanguageDisplayName())")
            Spacer()
        }
    }
    var bottomLine: some View {
        HStack(alignment: .center){
            if let longMemoryCount = bookcase.longMemoryBooksCount, let shortMemoryCount = bookcase.shortMemoryBooksCount {
                tvDefault(text: "\(longMemoryCount)")
                Image("longMemoryIcon").resizable().scaledToFit().frame(maxWidth: 26).padding(.trailing)
                tvDefault(text: "\(shortMemoryCount)")
                Image("shortMemoryIcon").resizable().scaledToFit().frame(maxWidth: 26)
            }
            Spacer()
        }.padding(.top, -8)
    }
}

/*
#Preview {
    let context = CoreDataManager.preview.viewContext
    let sampleBookcase = Bookcase(context: context)
    sampleBookcase.name = "Örnek Kitaplık (Preview)"
    sampleBookcase.createdDate = Date()
    sampleBookcase.learningLanguage = "ja"
    sampleBookcase.meaningLanguage = "tr"
    for i in 1...10 {
        let sampleBook = Book(context: context)
        sampleBook.learningWord = "Word \(i)"
        sampleBook.meaningWord = "Anlam \(i)"
        sampleBook.createdDate = Date()
        sampleBook.longMemory = i % 2 == 0 ? true : false
        sampleBook.shortMemory = i % 2 == 0 ? false : true
        sampleBook.bookcase = sampleBookcase
    }
    return BookcaseRow(bookcase: sampleBookcase, animalModel: getRandomAnimalModel(), onEdit: { print("edit") } , onDelete: {print("delete")}
    )
}
*/
