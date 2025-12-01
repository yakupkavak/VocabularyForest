//
//  BattleViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

// BattleViewModel.swift

import SwiftUI
import Combine

protocol BattleViewModelProtocol: ObservableObject, BattleSceneProtocol{
    func askQuestion()
    func prepareGame(
        bookcase: Bookcase?,
        questionType: BattleQuestionType,
        battleMode: BattleModeModel,
        gameLevel: GameLevel,
    )
    func checkAnswer(answerNumber: Int)
    func startMagic(magicType: MagicType)
    func nextQuestion()
    var questionStation: QuestionStation { get }
    var output: BattleViewModelOutputProcotol? { get set }
    var currentQuestion: QuestionModel? { get }
    var uiStation: BattleUIStation { get }
    var errorModel: BattleError? { get }
    var playerAnger: CharacterAnger? { get }
    var enemyAnger: CharacterAnger? { get }
}

protocol BattleViewModelOutputProcotol: AnyObject {
    func correctAnswer()
    func wrongAnswer()
    func enemyAttack()
    func startMagic(magic: MagicType)
    func setupGame(enemyCharacterModels: [String])
}

class BattleViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    private let coreData: CoreDataManager
    private var questionList: [QuestionModel] = []
    private var randomBooks: [Book] = []
    private var currentQuestionId = 0
    private var timer: Timer? = nil
    private var secondsElapsed = 0
    private var enemyList: [String]? = nil
    weak var output: BattleViewModelOutputProcotol?
    @Published var questionStation: QuestionStation = .notDetermined
    @Published var currentQuestion: QuestionModel?
    @Published var errorModel: BattleError? = nil
    @Published var uiStation: BattleUIStation = .notDetermined
    @Published var playerAnger: CharacterAnger?
    @Published var enemyAnger: CharacterAnger?
    
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

// MARK: - PRIVATE HELPERS

private extension BattleViewModel {
    func prepareEnemyLevel(gameLevel: GameLevel, characterName: String) {
        switch gameLevel {
        case .easy:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.enemyLevel, currentLevel: 0, name: characterName, imageFileName: "\(characterName)_profile_icon")
        case .medium:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.enemyLevel, currentLevel: 0, name: characterName, imageFileName: "\(characterName)_profile_icon")
        case .hard:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.enemyLevel, currentLevel: 0, name: characterName, imageFileName: "\(characterName)_profile_icon")
        case .insane:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.enemyLevel, currentLevel: 0, name: characterName, imageFileName: "\(characterName)_profile_icon")
        }
    }
    
    func preparePlayerLevel(gameLevel: GameLevel) {
        switch gameLevel {
        case .easy:
            playerAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "Ichigo", imageFileName: "men_profile_icon")
        case .medium:
            playerAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "Ichigo", imageFileName: "men_profile_icon")
        case .hard:
            playerAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "Ichigo", imageFileName: "men_profile_icon")
        case .insane:
            playerAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "Ichigo", imageFileName: "men_profile_icon")
        }
    }
    
    func setShortBooks(books: [Book], bookCount: Int) {
        let shortBooks = books.filter { (book: Book) -> Bool in
            return book.shortMemory == true
        }
        var questionNumber = 1
        for book in shortBooks.shuffled().prefix(bookCount){
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
    
    func setLongBooks(books: [Book], bookCount: Int) {
        let longBooks = books.filter { (book: Book) -> Bool in
            return book.longMemory == true
        }
        var questionNumber = 1
        for book in longBooks.prefix(bookCount){
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
    
    func gameOver() {
        print("gameOver")
    }
}

extension BattleViewModel: BattleViewModelProtocol {

    func prepareGame(
        bookcase: Bookcase?,
        questionType: BattleQuestionType,
        battleMode: BattleModeModel,
        gameLevel: GameLevel
    ) {
        output?.setupGame(enemyCharacterModels: battleMode.assetModels)
        enemyList = battleMode.assetModels
        guard let firstEnemyName = enemyList?.first else {
            errorModel = .emptyEnemyAsset
            return
        }
        preparePlayerLevel(gameLevel: gameLevel)
        prepareEnemyLevel(gameLevel: gameLevel, characterName: firstEnemyName)
        guard let books = coreData.fetchAllBooks() else {
            errorModel = .emptyBookcase
            return
        }
        questionList = []
        switch questionType {
        case .learning, .competitive:
            setShortBooks(books: books, bookCount: (gameLevel.playerLevel + gameLevel.enemyLevel + 1) * 8)
        case .remainder:
            setLongBooks(books: books, bookCount: (gameLevel.playerLevel + gameLevel.enemyLevel + 1) * 8)
        }
        askQuestion()
        
    }
    
    func askQuestion() {
        uiStation = .askQuestion
        if currentQuestionId >= questionList.count || questionList.isEmpty {
            errorModel = BattleError.emptyQuestionList
        }
        if let question = questionList[safe: currentQuestionId] {
            currentQuestion = question
        } else {
            errorModel = BattleError.emptyQuestionList
        }
    }
    
    func checkAnswer(answerNumber: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            uiStation = .checkAnswer
        }
        if let currentQuestion {
            if let answer = currentQuestion.answers[safe: answerNumber] {
                if answer.isTrue {
                    playerAnger?.currentLevel += 1
                    output?.correctAnswer()
                }else {
                    enemyAnger?.currentLevel += 1
                    output?.wrongAnswer()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.nextQuestion()
                }
            }
        }
    }
    
    func startMagic(magicType: MagicType) {
        uiStation = .notDetermined
        output?.startMagic(magic: magicType)
    }
    
    func nextQuestion() {
        questionStation = .waiting
        uiStation = .askQuestion
        currentQuestionId += 1
        if playerAnger?.currentLevel == playerAnger?.totalLevel {
            uiStation = .chooseMagic
        }else if enemyAnger?.currentLevel == enemyAnger?.totalLevel {
            uiStation = .notDetermined
            output?.enemyAttack()
        }else {
            askQuestion()
        }
    }
}

extension BattleViewModel: BattleSceneProtocol {
    func roundComplete() {
        playerAnger?.currentLevel = 0
        nextQuestion()
    }
    func startGame() {
        print("")
    }
}

