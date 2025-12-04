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
    private let audioService: AudioServiceProtocol
    private var questionList: [QuestionModel] = []
    private var answerBooks: [Book] = []
    private var currentQuestionId = 0
    private var timer: Timer? = nil
    private var secondsElapsed = 0
    private var enemyList: [EnemyCharacterModel]? = nil
    private var currentEnemyIndex = 0
    private var gameLevel: GameLevel? = nil
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

    init(coreDataManager: CoreDataManager = .shared, audioService: AudioServiceProtocol = ForestAudioService()) {
        self.coreData = coreDataManager
        self.audioService = audioService
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
                name: "Ichigo",
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        case .medium:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: "Ichigo",
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        case .hard:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: "Ichigo",
                imageFileName: "\(characterModel.assetName)_profile_icon"
            )
        case .insane:
            playerAnger = CharacterAnger(
                totalLevel: characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel,
                currentLevel: 0,
                name: "Ichigo",
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
    
    func setShortBooks(books: [Book], bookCount: Int) {
        let shortBooks = books.filter { (book: Book) -> Bool in
            return book.shortMemory == true
        }
        var questionNumber = 1
        for book in shortBooks.shuffled().prefix(bookCount){
            let randomBooks = Array(books.filter { (indexBook: Book) -> Bool in
                return indexBook != book && indexBook.bookcase?.unwrappedLearningLanguage == book.bookcase?.unwrappedLearningLanguage
            }.shuffled().prefix(3))
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
            answerBooks.append(book)
            questionNumber += 1
        }
    }
    
    func setLongBooks(books: [Book], bookCount: Int) {
        let longBooks = books.filter { (book: Book) -> Bool in
            return book.longMemory == true
        }
        var questionNumber = 1
        for book in longBooks.shuffled().prefix(bookCount){
            if let answer = book.learningWord {
                let randomBooks = Array(books.filter { (indexBook: Book) -> Bool in
                    return indexBook != book && indexBook.bookcase?.unwrappedLearningLanguage == book.bookcase?.unwrappedLearningLanguage
                }).shuffled().prefix(3)
                let formatString = NSLocalizedString("quiz_question_format", comment: "Learning vocabulary question title")
                let finalQuestionText = String(format: formatString, answer)
                let model = QuestionModel(
                    questionTitle: finalQuestionText,
                    answers: [
                        AnswerModel(answer: answer, isTrue: true),
                        AnswerModel(answer: randomBooks[safe: 0]?.unwrappedLearningWord ?? "Agile", isTrue: false),
                        AnswerModel(answer: randomBooks[safe: 1]?.unwrappedLearningWord ?? "Player", isTrue: false),
                        AnswerModel(answer: randomBooks[safe: 2]?.unwrappedLearningWord ?? "Who", isTrue: false),
                    ].shuffled(),
                    questionNumber: questionNumber
                )
                questionList.append(model)
                answerBooks.append(book)
                questionNumber += 1
            }
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
    func calculateMinBookCount(
        battleMode: BattleModeModel,
        gameLevel: GameLevel,
    ) -> Int{
        var totalCorrectBook = 0
        var totalWrongBook = 0
        let assetModels = battleMode.assetModels
        for characterModel in assetModels {
            totalCorrectBook += characterModel.isBoss ? gameLevel.bossLevel : gameLevel.enemyLevel
            totalWrongBook += gameLevel.playerLevel
        }
        return totalCorrectBook + totalWrongBook + 1
    }
}

// MARK: - BATTLE VIEW MODEL PROTOCOL

extension BattleViewModel: BattleViewModelProtocol {

    func prepareGame(
        bookcase: Bookcase?,
        questionType: BattleQuestionType,
        battleMode: BattleModeModel,
        gameLevel: GameLevel,
    ) {
        guard let books = coreData.fetchAllBooks() else {
            errorModel = .emptyBookcase
            return
        }
        let minBook = calculateMinBookCount(battleMode: battleMode, gameLevel: gameLevel)
        self.gameLevel = gameLevel
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
                    gameStatus.trueCount += 1
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
        gameStatus.userWon = true
        uiStation = .gameOver
    }
}

