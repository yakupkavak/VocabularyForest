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
    
    private var healthNotificationIDs: [String] {
        return ["health_limit_50","health_limit_20", "health_limit_10", "health_limit_0"]
    }

    func cancelHealthNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: healthNotificationIDs)
    }

    func scheduleHealthNotification(targetValue: Int, timeInterval: TimeInterval) {
        guard timeInterval > 60 else { return }
        
        let id = "health_limit_\(targetValue)"
        var title = ""
        var body = ""
        
        switch targetValue {
        case 50:
            title = "Orman Sağlığı yarılandı!"
            body = "Orman sağlığı %50'nin altına inmek üzere. Solmaya başlıyor."
        case 20:
            title = "Orman Sağlığı Düşüyor!"
            body = "Orman sağlığı %20'nin altına inmek üzere. İlgilenmen gerek."
        case 10:
            title = "🚨 KRİTİK DURUM!"
            body = "Orman sağlığı %10 seviyesine geriledi! Orman ölüyor!"
        case 0:
            title = "ORMAN KURUDU!"
            body = "Sağlık %0 oldu. Orman tamamen kurudu."
        default:
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Sağlık bildirimi kurulamadı: \(error.localizedDescription)")
            } else {
                print("🏥 Bildirim kuruldu: %\(targetValue) sınırı için \(Int(timeInterval/60)) dakika sonra.")
            }
        }
    }
    
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
        content.title = String(localized:"Kelimemiz: \(learningWord) 📚")
        content.subtitle = String(localized:"Meaning: \(meaningWord) 🥰")
        content.body = String(localized:"Description: \(description)")
        
        return content
    }
    
    private func askExample(learningWord: String, meaningWord: String, example: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized:"Kelimemiz: \(learningWord) 📚")
        content.subtitle = String(localized:"Meaning: \(meaningWord) 🥰")
        content.body = String(localized:"Example: \(example)")
        
        return content
    }
    
    private func askWordAndMeaning(learningWord: String, meaningWord: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = getRandomWordTitle()
        content.subtitle = String(localized:"\(learningWord)")
        content.body = String(localized:"Meaning: \(meaningWord)")
        
        return content
    }
    
    private func getRandomWordTitle() -> String {
        let titleList = [String(localized: "Hatırlama Vakti 📚"), String(localized:"Öğrenme Zamanı 🥰"), String(localized:"Bunu hatırlıyor musun 👀")]
        return titleList.randomElement() ?? String(localized:"Hatırlama Vakti 📚")
    }
}
