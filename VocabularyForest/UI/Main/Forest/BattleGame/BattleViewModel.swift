//
//  BattleViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

// BattleViewModel.swift

import SwiftUI
import Combine

protocol BattleViewModelProtocol: ObservableObject {
    func askQuestion()
    func prepareQuestions(bookcase: Bookcase?, gameMode: BattleGameType)
    func checkAnswer(answerNumber: Int)
    func startMagic(magicType: MagicType)
    var questionStation: QuestionStation { get }
    var output: BattleViewModelOutputProcotol? { get set }
    var currentQuestion: QuestionModel? { get }
    var uiStation: BattleUIStation { get }
    var errorModel: BattleError? { get }
}

protocol BattleViewModelOutputProcotol: AnyObject {
    func correctAnswer()
    func wrongAnswer()
    func enemyAttack()
    func startMagic(magic: MagicType)
}

class BattleViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    private let coreData: CoreDataManager
    private var questionList: [QuestionModel] = []
    private var randomBooks: [Book] = []
    private var currentQuestionId = 0
    private var timer: Timer? = nil
    private var secondsElapsed = 0
    weak var output: BattleViewModelOutputProcotol?
    @Published var questionStation: QuestionStation = .notDetermined
    @Published var currentQuestion: QuestionModel?
    @Published var errorModel: BattleError? = nil
    @Published var uiStation: BattleUIStation = .notDetermined
    
    init(coreDataManager: CoreDataManager = .shared) {
            self.coreData = coreDataManager
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
            guard let self else { return }
            secondsElapsed += 1
            if secondsElapsed == 2 {
                questionStation = .waiting
                uiStation = .askQuestion
                self.timer = nil
            }
        })
    }
}

extension BattleViewModel: BattleViewModelProtocol {

    func prepareQuestions(bookcase: Bookcase?, gameMode: BattleGameType) {
        guard let books = coreData.fetchAllBooks() else {
            errorModel = .emptyBookcase
            return
        }
        questionList = []
        switch gameMode {
            case .learning, .competitive:
                setShortBooks(books: books)
            case .remainder:
                setLongBooks(books: books)
        }
        askQuestion()
    }
    
    private func setShortBooks(books: [Book]) {
        let shortBooks = books.filter { (book: Book) -> Bool in
            return book.shortMemory == true
        }
        var questionNumber = 1
        for book in shortBooks.shuffled().prefix(10){
            let randomBooks = Array(books.filter { (indexBook: Book) -> Bool in
                return indexBook != book && indexBook.bookcase?.unwrappedLearningLanguage == book.bookcase?.unwrappedLearningLanguage
            }.prefix(3))
            let formatString = NSLocalizedString("quiz_question_format", comment: "Learning vocabulary question title")
            let finalQuestionText = String(format: formatString, book.unwrappedLearningWord)
            let model = QuestionModel(
                questionTitle: finalQuestionText,
                answers: [
                    AnswerModel(answer: book.unwrappedMeaningWord, isTrue: true),
                    AnswerModel(answer: randomBooks[safe: 0]?.unwrappedMeaningWord ?? "Agile", isTrue: false),
                    AnswerModel(answer: randomBooks[safe: 1]?.unwrappedMeaningWord ?? "Player", isTrue: false),
                    AnswerModel(answer: randomBooks[safe: 2]?.unwrappedMeaningWord ?? "Who", isTrue: false),
                ].shuffled(),
                questionNumber: questionNumber
            )
            questionList.append(model)
            questionNumber += 1
        }
    }
    
    private func setLongBooks(books: [Book]) {
        let longBooks = books.filter { (book: Book) -> Bool in
            return book.longMemory == true
        }
        var questionNumber = 1
        for book in longBooks.prefix(10){
            if let answer = book.learningWord {
                let randomBooks = Array(books.filter { (indexBook: Book) -> Bool in
                    return indexBook != book || indexBook.bookcase?.unwrappedLearningLanguage == book.bookcase?.unwrappedLearningLanguage
                }.prefix(3))
                let formatString = NSLocalizedString("quiz_question_format", comment: "Learning vocabulary question title")
                let finalQuestionText = String(format: formatString, answer)
                let model = QuestionModel(
                    questionTitle: finalQuestionText,
                    answers: [
                        AnswerModel(answer: answer, isTrue: true),
                        AnswerModel(answer: randomBooks[safe: 0]?.unwrappedLearningWord ?? "Agile", isTrue: false),
                        AnswerModel(answer: randomBooks[safe: 1]?.unwrappedLearningWord ?? "Player", isTrue: false),
                        AnswerModel(answer: randomBooks[safe: 2]?.unwrappedLearningWord ?? "Who", isTrue: false),
                    ],
                    questionNumber: questionNumber
                )
                questionList.append(model)
                questionNumber += 1
            }
        }
    }
    
    func askQuestion() {
        if currentQuestionId > questionList.count + 1 || questionList.isEmpty {
            errorModel = BattleError.emptyQuestionList
        }
        if let question = questionList[safe: currentQuestionId] {
            currentQuestion = question
        } else {
            errorModel = BattleError.emptyQuestionList
        }
    }
    
    func checkAnswer(answerNumber: Int) {
        if let currentQuestion {
            if let answer = currentQuestion.answers[safe: answerNumber] {
                if answer.isTrue {
                    questionStation = .correct
                }else {
                    questionStation = .wrong
                }
            }
        }
    }
    
    func startMagic(magicType: MagicType) {
        output?.startMagic(magic: magicType)
    }
    
}

enum BattleUIStation {
    case chooseMagic
    case askQuestion
    case notDetermined
}

enum QuestionStation {
    case correct
    case wrong
    case waiting
    case timeOut
    case notDetermined
}

enum BattleError: Error {
    case emptyBookcase
    case emptyQuestionList
    case unexpectedError
}


extension BattleViewModel: BattleSceneProtocol {
    func roundComplete() {
        print("")
    }
    func startGame() {
        print("")
    }
}

