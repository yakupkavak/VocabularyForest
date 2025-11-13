//
//  NotificationManager.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 6.11.2025.
//

import UserNotifications
import Combine
import UIKit

class NotificationManager: ObservableObject {
    
    // MARK: - PROPERTIES
    
    @MainActor
    @Published var notificationsEnabled: Bool = false
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - INIT

    private init() {
        Task {
            await checkNotificationStatus()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - HELPERS
    
    @objc private func handleAppDidBecomeActive() {
        Task {
            await checkNotificationStatus()
            }
    }

    @MainActor
    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let newStatus = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
        if self.notificationsEnabled != newStatus {
            self.notificationsEnabled = newStatus
        }
    }
    
    @MainActor
    func requestEnable() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                self.notificationsEnabled = granted
                
            } catch {
                self.notificationsEnabled = false
            }
            
        case .denied:
            await openAppSettings()
        case .authorized, .provisional, .ephemeral:
            if !self.notificationsEnabled {
                self.notificationsEnabled = true
            }
        @unknown default:
            self.notificationsEnabled = false
        }
    }

    @MainActor
    func requestDisable() async {
        await openAppSettings()
    }

    @MainActor
    private func openAppSettings() async {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            await UIApplication.shared.open(url)
        }
    }
    
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
