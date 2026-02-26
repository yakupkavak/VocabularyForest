//
//  BattleViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

// BattleViewModel.swift

import Combine
import Foundation

protocol BattleViewModelProtocol: ObservableObject, BattleSceneProtocol{
    func askQuestion()
    func prepareGame(
        bookcaseModel: BookcaseModel?,
        questionType: BattleQuestionType,
        battleMode: BattleEnemyModel,
        gameLevel: GameLevel,
    )
    func checkAnswer(answerNumber: Int)
    func startMagic(magicType: MagicType)
    func nextQuestion()
    func updateAudioSettings(music: Double, sfx: Double, isMuted: Bool)
    func playSoundEffect(name: String)
    func stopGameMusic()
    func startGameMusic()
    var questionStation: QuestionStation { get }
    var output: BattleViewModelOutputProcotol? { get set }
    var currentQuestion: QuestionModel? { get }
    var uiStation: BattleUIStation { get }
    var errorModel: BattleError? { get }
    var playerAnger: CharacterAnger? { get }
    var enemyAnger: CharacterAnger? { get }
    var gameStatus: GameStatusModel { get }
}

protocol BattleViewModelOutputProcotol: AnyObject {
    func correctAnswer()
    func wrongAnswer()
    func enemyAttack()
    func startMagic(magic: MagicType)
    func setupGame(enemyCharacterModels: [EnemyCharacterModel])
    func setupNextEnemy()
}

class BattleViewModel: ObservableObject {
    
    // MARK: - PROPERTIES
    
    private let coreData: CoreDataManager
    private let forestDataManager: ForestDataManager
    private let audioService: AudioServiceProtocol
    private var questionList: [QuestionModel] = []
    private var answerBooks: [BookModel] = []
    private var currentQuestionId = 0
    private var timer: Timer? = nil
    private var secondsElapsed = 0
    private var enemyList: [EnemyCharacterModel]? = nil
    private var currentEnemyIndex = 0
    private var gameLevel: GameLevel? = nil
    private var questionType: BattleQuestionType? = nil
    private var battleMode: BattleEnemyModel? = nil
    weak var output: BattleViewModelOutputProcotol?
    
    // MARK: - PUBLISHED PROPERTIES

    @Published var questionStation: QuestionStation = .notDetermined
    @Published var currentQuestion: QuestionModel?
    @Published var errorModel: BattleError? = nil
    @Published var uiStation: BattleUIStation = .notDetermined
    @Published var playerAnger: CharacterAnger?
    @Published var enemyAnger: CharacterAnger?
    @Published var gameStatus: GameStatusModel = GameStatusModel(
        trueCount: 0,
        wrongCount: 0,
        wrongWords: []
    )

    init(coreDataManager: CoreDataManager = .shared, audioService: AudioServiceProtocol = ForestAudioService.shared, forestDataManager: ForestDataManager = .shared) {
        self.coreData = coreDataManager
        self.audioService = audioService
        self.forestDataManager = forestDataManager
        
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
    
    func prepareEnemyLevel(gameLevel: GameLevel, characterModel: EnemyCharacterModel) {
        switch gameLevel {
        case .easy:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: String(localized: "Ichigo"),
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        case .medium:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: String(localized:"Ichigo"),
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        case .hard:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: String(localized:"Ichigo"),
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        case .insane:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: String(localized:"Ichigo"),
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        }
        enemyAnger?.name = characterModel.characterName
    }
    
    func preparePlayerLevel(gameLevel: GameLevel) {
        switch gameLevel {
        case .easy:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "", imageFileName: "men_profile_icon")
        case .medium:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "", imageFileName: "men_profile_icon")
        case .hard:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "", imageFileName: "men_profile_icon")
        case .insane:
            enemyAnger = CharacterAnger(totalLevel: gameLevel.playerLevel, currentLevel: 0, name: "", imageFileName: "men_profile_icon")
        }
    }
    
    //Learning modunu seçerken kitapların example ya da descriptionu olan halini veriyoruz.
    func setShortBooks(books: [BookModel], bookCount: Int) {
        let shortBooks = books.filter { (book: BookModel) -> Bool in
            return book.shortMemory == true
        }
        var questionNumber = 1
        for book in shortBooks.shuffled().prefix(bookCount){
            let answer = book.learningWord
            let answerBookcase = coreData.fetchSafeBookcase(book: book, contextType: .main)
            let randomBooks = Array(books.filter { (indexBook: BookModel) -> Bool in
                let indexBookcase = coreData.fetchSafeBookcase(book: indexBook, contextType: .main)
                return indexBook != book && indexBookcase?.learningLanguage == answerBookcase?.learningLanguage && indexBook.meaningWord != book.meaningWord
            }.shuffled().prefix(3))
            let formatString = NSLocalizedString("quiz_question_format", comment: "Learning vocabulary question title")
            let finalQuestionText = String(format: formatString, book.learningWord.firstUppercased)
            let model = QuestionModel(
                questionTitle: finalQuestionText,
                answers: [
                    AnswerModel(book: book, answer: book.meaningWord, isTrue: true),
                    AnswerModel(book: nil, answer: randomBooks[safe: 0]?.meaningWord ?? "Agile", isTrue: false),
                    AnswerModel(book: nil, answer: randomBooks[safe: 1]?.meaningWord ?? "Player", isTrue: false),
                    AnswerModel(book: nil, answer: randomBooks[safe: 2]?.meaningWord ?? "Who", isTrue: false),
                ].shuffled(),
                questionNumber: questionNumber,
                description: book.learningWord,
                example: book.exampleSentence,
            )
            questionList.append(model)
            answerBooks.append(book)
            questionNumber += 1
        }
    }
    
    func setLongBooks(books: [BookModel], bookCount: Int) {
        let longBooks = books.filter { (book: BookModel) -> Bool in
            return book.longMemory == true
        }
        var questionNumber = 1
        for book in longBooks.shuffled().prefix(bookCount){
            let answer = book.learningWord
            let answerBookcase = coreData.fetchSafeBookcase(book: book, contextType: .main)
            let randomBooks = Array(books.filter { (indexBook: BookModel) -> Bool in
                let indexBookcase = coreData.fetchSafeBookcase(book: indexBook, contextType: .main)
                return indexBook != book && indexBookcase?.learningLanguage == answerBookcase?.learningLanguage && indexBook.meaningWord != book.meaningWord
            }).shuffled().prefix(3)
            let formatString = NSLocalizedString("quiz_question_format", comment: "Learning vocabulary question title")
            let finalQuestionText = String(format: formatString, answer)
            let model = QuestionModel(
                questionTitle: finalQuestionText,
                answers: [
                    AnswerModel(book: book,answer: book.meaningWord, isTrue: true),
                    AnswerModel(book: nil,answer: randomBooks[safe: 0]?.meaningWord ?? "Agile", isTrue: false),
                    AnswerModel(book: nil,answer: randomBooks[safe: 1]?.meaningWord ?? "Player", isTrue: false),
                    AnswerModel(book: nil,answer: randomBooks[safe: 2]?.meaningWord ?? "Who", isTrue: false),
                ].shuffled(),
                questionNumber: questionNumber,
                description: nil,
                example: nil,
            )
            questionList.append(model)
            answerBooks.append(book)
            questionNumber += 1
        }
    }
    
    func gameOver() {
        uiStation = .gameOver
    }
    
    func nextEnemy() {
        currentEnemyIndex += 1
        if let nextEnemy = enemyList?[safe: currentEnemyIndex], let safeGameLevel = gameLevel {
            enemyAnger?.currentLevel = 0
            prepareEnemyLevel(gameLevel: safeGameLevel, characterModel: nextEnemy)
        }
    }
}

// MARK: - BATTLE VIEW MODEL PROTOCOL

extension BattleViewModel: BattleViewModelProtocol {

    func prepareGame(
        bookcaseModel: BookcaseModel?,
        questionType: BattleQuestionType,
        battleMode: BattleEnemyModel,
        gameLevel: GameLevel,
    ) {
        var books: [BookModel] = []
        
        if questionType == .learning {
            if let bookcaseModel {
                guard let bookcase = coreData.fetchBookcase(
                    name: bookcaseModel.bookcaseName,
                    learningLanguageCode: bookcaseModel.learningLanguage,
                    meaningLanguageCode: bookcaseModel.meaningLanguage,
                    contextType: .main
                ) else {
                    errorModel = .emptyBookcase
                    return
                }
                guard let spesificBooks = coreData.fetchSafeBooksExampleDescription(model: bookcase, contextType: .background) else {
                    errorModel = .emptyBookcase
                    return
                }
                books = spesificBooks
            } else {
                guard let allBooks = coreData.fetchAllBooksWithExampleDescription(contextType: .background) else {
                    errorModel = .emptyBookcase
                    return
                }
                books = allBooks
            }
        } else {
            if let bookcaseModel {
                guard let bookcase = coreData.fetchBookcase(
                    name: bookcaseModel.bookcaseName,
                    learningLanguageCode: bookcaseModel.learningLanguage,
                    meaningLanguageCode: bookcaseModel.meaningLanguage,
                    contextType: .background
                ) else {
                    errorModel = .emptyBookcase
                    return
                }
                guard let spesificBooks = coreData.fetchBooks(
                    model: bookcase,
                    contextType: .background
                ) else {
                    errorModel = .emptyBookcase
                    return
                }
                books = spesificBooks
            } else {
                guard let allBooks = coreData.fetchAllSafeBooks(contextType: .background) else {
                    errorModel = .emptyBookcase
                    return
                }
                books = allBooks
            }
        }
        
        let minBook = calculateMinBookCount(battleMode: battleMode, gameLevel: gameLevel)
        self.gameLevel = gameLevel
        self.questionType = questionType
        self.battleMode = battleMode
        output?.setupGame(enemyCharacterModels: battleMode.assetModels)
        enemyList = battleMode.assetModels
        guard let firstEnemy = enemyList?.first else {
            errorModel = .emptyEnemyAsset
            return
        }
        preparePlayerLevel(gameLevel: gameLevel)
        prepareEnemyLevel(gameLevel: gameLevel, characterModel: firstEnemy)
        questionList = []
        switch questionType {
        case .learning, .competitive:
            setShortBooks(books: books, bookCount: minBook)
        case .remainder:
            setLongBooks(books: books, bookCount: minBook)
        }
        uiStation = .notDetermined
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.askQuestion()
        }
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
                    gameStatus.trueCount += 1
                    if let questionType, let answerBook = answer.book {
                        coreData.updateBookAnswer(book: answerBook, type: questionType, contextType: .main)
                        // TODO: SHOW SAVE ERROR
                        let saveResult = forestDataManager.correctAnswer(questionType: questionType, contextType: .main)
                    }
                    output?.correctAnswer()
                }else {
                    enemyAnger?.currentLevel += 1
                    gameStatus.wrongCount += 1
                    if let answerBook = answerBooks[safe: currentQuestionId] {
                        gameStatus.wrongWords.append(answerBook)
                    }
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
    
    func startGameMusic() {
        audioService.playBackgroundMusic()
    }
    
    func stopGameMusic() {
        audioService.stopMusic()
    }
    
    func updateAudioSettings(music: Double, sfx: Double, isMuted: Bool) {
        audioService.updateVolume(musicLevel: music, sfxLevel: sfx, isMuted: isMuted)
    }
    
    func playSoundEffect(name: String) {
        audioService.playSFX(filename: name)
    }
}

// MARK: - BATTLE SCENE PROTOCOL

extension BattleViewModel: BattleSceneProtocol {
    func roundComplete() {
        output?.setupNextEnemy()
        playerAnger?.currentLevel = 0
        nextQuestion()
        nextEnemy()
    }
    func playerDead() {
        gameStatus.userWon = false
        uiStation = .gameOver
    }
    func playerWon() {
        if let gameLevel, let questionType, let battleMode {
            let result = forestDataManager.winGame(
                gameLevel: gameLevel,
                battleEnemyMode: battleMode,
                gameType: questionType,
                contextType: .main
            )
            switch result.status {
            case .success:
                print("player won saved")
            case .loading:
                print("")
            case .error:
                print("couldn't save progress")
            }
        }
        gameStatus.userWon = true
        uiStation = .gameOver
    }
}

