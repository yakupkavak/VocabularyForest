//
//  FlashCardViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.11.2025.
//

import SwiftUI
import Combine

enum QuestionType: CaseIterable {
    case definition
    case fillInTheBlank
    case description
}

class FlashCardViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    private var manager: CoreDataManager
    private var books: [Book] = []
    private var currentIndex = 0
    private let durationAndDelay: CGFloat = 0.3

    // MARK: - PUBLISHED PROPERTIES
    
    @Published var currentBook: Book?
    @Published var currentQuestionType: QuestionType = .definition
    @Published var noWordsFound = false
    @Published var backDegree = 90.0
    @Published var frontDegree = 0.0
    @Published var isFlipped = false
    
    // MARK: - INIT
    
    init(manager: CoreDataManager = .shared) {
        self.manager = manager
        fetchBooks()
        updateCurrentBook()
    }
    
    // MARK: - DATA FUNCTIONS
    
    private func fetchBooks() {
        self.books = manager.fetchAllBooks() ?? []
        noWordsFound = books.isEmpty
    }
    
    private func updateCurrentBook() {
        guard !books.isEmpty else {
            currentBook = nil
            return
        }
        currentBook = books[currentIndex]
        pickRandomQuestion()
    }

    private func pickRandomQuestion() {
        var availableTypes: [QuestionType] = [.definition]
        
        guard let book = currentBook else {
            currentQuestionType = .definition
            return
        }

        if let description = book.descriptionWord, !description.isEmpty {
            availableTypes.append(.description)
        }

        let example = book.exampleSentence ?? ""
        let wordToFind = book.unwrappedLearningWord
        if !example.isEmpty,
           !wordToFind.isEmpty,
           example.range(of: wordToFind, options: .caseInsensitive) != nil {
            availableTypes.append(.fillInTheBlank)
        }
        
        currentQuestionType = availableTypes.randomElement() ?? .definition
    }
    
    // MARK: - VIEW HELPERS

    func flipCard () {
        isFlipped.toggle()
        if isFlipped {
            withAnimation(.linear(duration: durationAndDelay)) { frontDegree = -90 }
            withAnimation(.linear(duration: durationAndDelay).delay(durationAndDelay)){ backDegree = 0 }
        } else {
            withAnimation(.linear(duration: durationAndDelay)) { backDegree = 90 }
            withAnimation(.linear(duration: durationAndDelay).delay(durationAndDelay)){ frontDegree = 0 }
        }
    }
    
    func markCard(remembered: Bool) {
        guard let currentBook = currentBook else { return }
        currentBook.longMemory = remembered
        currentBook.shortMemory = !remembered
        manager.save()
        goToNextCard()
    }
    
    private func goToNextCard() {
        if isFlipped {
            flipCard()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + durationAndDelay) {
            if self.books.isEmpty { return }
            self.currentIndex = (self.currentIndex + 1) % self.books.count
            self.updateCurrentBook()
        }
    }
}
