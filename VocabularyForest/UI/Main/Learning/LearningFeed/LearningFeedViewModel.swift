//
//  LearningFeedViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.11.2025.
//

import Combine
import Foundation

class LearningFeedViewModel: ObservableObject{
    
    // MARK: - DEPENDENCIES
    private let dataManager: CoreDataManagerProtocol
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - PROPERTIES
    
    @Published var todaysLearningWord = ""
    @Published var todaysMeaning = ""
    @Published var todaysExample = ""
    @Published var todaysDescription = ""
    @Published var alert = LearningFeedAlertType.none
    
    // MARK: - INIT
    
    init(coreDataManager: CoreDataManagerProtocol, analyticsService: AnalyticsServiceProtocol = NoopAnalyticsService()) {
        self.dataManager = coreDataManager
        self.analyticsService = analyticsService
        fetchDailyWord()
    }
    
    // MARK: - HELPERS
    
    func fetchDailyWord() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let lastFetchedDate = defaults.object(forKey: Constant.lastFetchedDateKey) as? Date
        if let lastDate = lastFetchedDate, calendar.isDateInToday(lastDate) {
            todaysLearningWord = defaults.string(forKey: Constant.dailyWordKey) ?? ""
            todaysMeaning = defaults.string(forKey: Constant.dailyMeaningKey) ?? ""
            todaysExample = defaults.string(forKey: Constant.dailyExampleKey) ?? ""
            todaysDescription = defaults.string(forKey: Constant.dailyDescriptionKey) ?? ""
            if todaysLearningWord.isEmpty {
                alert = .emptyWord
            } else {
                analyticsService.log(.dailyWordViewed)
            }

        } else {
            fetchNewWordFromCoreData()
        }
    }
    
    public func forceFetchNewWord() {
        fetchNewWordFromCoreData()
    }
    
    // MARK: - PRIVATE HELPERS
    
    private func fetchNewWordFromCoreData() {
        guard let bookcases = dataManager.fetchSafeBookcases(
            sortDescriptors: nil,
            contextType: .main
        ), !bookcases.isEmpty else {
            alert = .emptyBookcase
            clearDailyWord()
            return
        }
        
        guard let randomBookcase = bookcases.randomElement() else {
            alert = .emptyBookcase
            clearDailyWord()
            return
        }
        
        guard let books = dataManager.fetchSafeBooks(
            model: randomBookcase,
            sortDescriptors: nil,
            contextType: .main
        ) else { return }
        
        if let randomBook = books.randomElement() {
            todaysLearningWord = randomBook.learningWord
            todaysMeaning = randomBook.meaningWord
            todaysExample = randomBook.exampleSentence ?? ""
            todaysDescription = randomBook.descriptionWord ?? ""
            alert = .none
            saveDailyWord()
            analyticsService.log(.dailyWordViewed)

        } else {
            alert = .emptyWord
            clearDailyWord()
        }
    }
    
    private func saveDailyWord() {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: Constant.lastFetchedDateKey) // Şu anın tarihini kaydet
        defaults.set(todaysLearningWord, forKey: Constant.dailyWordKey)
        defaults.set(todaysMeaning, forKey: Constant.dailyMeaningKey)
        defaults.set(todaysExample, forKey: Constant.dailyExampleKey)
    }
    
    private func clearDailyWord() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constant.lastFetchedDateKey)
        defaults.removeObject(forKey: Constant.dailyWordKey)
        defaults.removeObject(forKey: Constant.dailyMeaningKey)
        defaults.removeObject(forKey: Constant.dailyExampleKey)
        defaults.removeObject(forKey: Constant.dailyDescriptionKey)
        todaysLearningWord = ""
        todaysMeaning = ""
        todaysExample = ""
        todaysDescription = ""
    }
}

private extension LearningFeedViewModel {
    enum Constant {
        static let lastFetchedDateKey = "lastFetchedDate"
        static let dailyWordKey = "dailyWord"
        static let dailyMeaningKey = "dailyMeaning"
        static let dailyExampleKey = "dailyExample"
        static let dailyDescriptionKey = "dailyDescription"
    }
}
enum LearningFeedAlertType{
    case emptyBookcase
    case emptyWord
    case none
}
