//
//  NotificationManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.11.2025.
//

import UserNotifications

class NotificationManager {
    
    // MARK: - PROPERTIES
    
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - INIT

    private init() { }
    
    // MARK: - HELPERS

    func createNotification(bookId: String,
                            learningWord: String, meaningWord: String, description: String, example: String) {
        let randomHour = Int.random(in: (8...22))
        let randomMinute = Int.random(in: (0...59))
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = randomHour
        dateComponents.minute = randomMinute
        var content: UNMutableNotificationContent?
        
        if description.isEmpty && example.isEmpty && !learningWord.isEmpty && !meaningWord.isEmpty{
            content = askWordAndMeaning(learningWord: learningWord, meaningWord: meaningWord)
        }else if description.isEmpty && !learningWord.isEmpty && !meaningWord.isEmpty && !example.isEmpty{
            content = askExample(learningWord: learningWord, meaningWord: meaningWord, example: example)
        }else if example.isEmpty && !learningWord.isEmpty && !meaningWord.isEmpty {
            content = askDescription(learningWord: learningWord, meaningWord: meaningWord, description: description)
        }else {
            print("Yeni notification yaratılamadı")
        }
        
        if let content {
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: bookId, content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request) { error in
                if let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func deleteNotification(bookId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [bookId])
    }
    
    func removeAllNotification() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - PRIVATE HELPERS
    
    private func askDescription(learningWord: String, meaningWord: String, description: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Kelimemiz  : \(learningWord) 📚"
        content.subtitle = "Anlamı     : \(meaningWord) 🥰"
        content.body = "Açıklaması : \(description)"
        
        return content
    }
    
    private func askExample(learningWord: String, meaningWord: String, example: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Kelimemiz  : \(learningWord) 📚"
        content.subtitle = "Anlamı     : \(meaningWord) 🥰"
        content.body = "Örneği     : \(example)"
        
        return content
    }
    
    private func askWordAndMeaning(learningWord: String, meaningWord: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = getRandomWordTitle()
        content.subtitle = "\(learningWord)"
        content.body = "Anlamı: \(meaningWord)"
        
        return content
    }
    
    private func getRandomWordTitle() -> String {
        let titleList = ["Hatırlama Vakti 📚", "Öğrenme Zamanı 🥰", "Bunu hatırlıyor musun 👀"]
        return titleList.randomElement() ?? "Hatırlama Vakti 📚"
    }
}
