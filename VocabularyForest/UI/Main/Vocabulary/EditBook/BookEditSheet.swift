//
//  EditBookcaseUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//
import SwiftUI

struct BookEditSheet: View {
    
    // MARK: - Properties
    
    let onSave: (String, String, String?, String?) -> Void
    @State private var learningWord: String
    @State private var meaningWord: String
    @State private var descriptionWord: String
    @State private var exampleSentence: String
    @Environment(\.dismiss) var dismiss
    
    init(book: Book, onSave: @escaping (String, String, String?, String?) -> Void) {
        self.onSave = onSave
        
        _learningWord = State(initialValue: book.unwrappedLearningWord)
        _meaningWord = State(initialValue: book.unwrappedMeaningWord)
        _descriptionWord = State(initialValue: book.descriptionWord ?? "")
        _exampleSentence = State(initialValue: book.exampleSentence ?? "")
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kelime") {
                    TextField("Öğrenilen Kelime", text: $learningWord)
                }
                Section("Anlam") {
                    TextField("Anlamı", text: $meaningWord)
                }
                
                Section("Detaylar (Opsiyonel)") {
                    VStack(alignment: .leading) {
                        Text("Açıklama")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextEditor(text: $descriptionWord)
                            .frame(minHeight: 80)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Örnek Cümle")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextEditor(text: $exampleSentence)
                            .frame(minHeight: 80)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Kelimeyi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveChanges()
                    }
                    .disabled(learningWord.isEmpty || meaningWord.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func saveChanges() {
        onSave(
            learningWord,
            meaningWord,
            descriptionWord,
            exampleSentence
        )
        dismiss()
    }
}
