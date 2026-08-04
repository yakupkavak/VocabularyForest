//
//  EditBookcaseUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

import SwiftUI

import SwiftUI
import CoreData

struct BookcaseEditSheet: View {
    
    // MARK: - Properties
    
    let item: BookcaseDisplayItem
    let onSave: (String, Language, Language) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var learningLanguage: Language?
    @State private var meaningLanguage: Language?
    @State private var isShowingLearnPicker = false
    @State private var isShowingMeanPicker = false
    
    // MARK: - Init
    
    init(item: BookcaseDisplayItem, onSave: @escaping (String, Language, Language) -> Void) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item.bookcase.bookcaseName)
        _learningLanguage = State(initialValue: LanguageData.allLanguages.first(where: {
            $0.id == item.bookcase.learningLanguage
        }))
        _meaningLanguage = State(initialValue: LanguageData.allLanguages.first(where: {
            $0.id == item.bookcase.meaningLanguage
        }))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kitaplık Adı") {
                    TextField("Kitaplık Adı", text: $name)
                }
                
                Section("Diller") {
                    Button {
                        isShowingLearnPicker = true
                    } label: {
                        HStack {
                            Text("Öğrenilen Dil")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(learningLanguage?.localizedName ?? "Seç")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        isShowingMeanPicker = true
                    } label: {
                        HStack {
                            Text("Anlam Dili")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(meaningLanguage?.localizedName ?? "Seç")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Kitaplığı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveChanges()
                    }
                    .disabled(learningLanguage == nil || meaningLanguage == nil || name.isEmpty)
                }
            }
        }
        .sheet(isPresented: $isShowingLearnPicker) {
            SelectLanguageUI(selectedLanguage: $learningLanguage, dismissLanguage: $meaningLanguage)
        }
        .sheet(isPresented: $isShowingMeanPicker) {
            SelectLanguageUI(selectedLanguage: $meaningLanguage, dismissLanguage: $learningLanguage)
        }
    }
    
    // MARK: - Functions
    
    private func saveChanges() {
        guard let learningLang = learningLanguage,
              let meaningLang = meaningLanguage else {
            return
        }
        
        onSave(name, learningLang, meaningLang)
        dismiss()
    }
}

#Preview {
    let manager = CoreDataManager.preview
    let sampleBookcase = manager.fetchSafeBookcases(contextType: .main)!.first!
        let sampleItem = BookcaseDisplayItem(
            id: sampleBookcase.id,
            bookcase: sampleBookcase,
            animalModel: AnimalBodyModel(head: "fox", foot: "fox")
        )
        BookcaseEditSheet(item: sampleItem, onSave: { _, _, _ in })
    
}
