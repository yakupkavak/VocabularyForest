//
//  SettingsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.11.2025.
//

import SwiftUI
import CoreData
import UserNotifications
import Combine

struct PolicyContent: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

class SettingsViewModel: ObservableObject {
    
    // MARK: - Properties
    
    private var manager: CoreDataManager
    @Published var sheetContent: PolicyContent? = nil
    @Published var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled") {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                requestNotificationPermission()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    // MARK: - Init
    
    init(manager: CoreDataManager = .shared) {
        self.manager = manager
    }
    
    // MARK: - HELPERS

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                }
            }
            if let error = error {
                print("Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    func openAppStoreReview() {
        let appID = "YOUR_APP_ID"
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    func showTermsOfUse() {
        sheetContent = PolicyContent(
            title: "Kullanım Koşulları",
            text: """

            Uygulamayı App Store'dan indirdiğiniz için, varsayılan olarak Apple'ın Standart Lisans Sözleşmesi'ni (EULA) kabul etmiş olursunuz.
            
            Uygulamayı kullanarak, bu koşullara uymayı kabul edersiniz.
            
            1. Lisans
            VocabularyForest, size bu uygulamayı kişisel, ticari olmayan kullanımınız için sınırlı, devredilemez bir lisans vermektedir.
            
            2. İçerik
            Girdiğiniz tüm kelimeler (learningWord, meaningWord, vb.) cihazınızda yerel olarak saklanır ve sunucularımıza gönderilmez. Verilerinizin sahibi sizsiniz.
            
            3. Sınırlamalar
            Uygulamayı yasa dışı amaçlar için kullanamazsınız...
            
            """
        )
    }
    
    func showPrivacyPolicy() {
        sheetContent = PolicyContent(
            title: "Gizlilik Politikası",
            text: """
            
            Son Güncelleme: 5 Kasım 2025
            
            VocabularyForest ("biz", "bizim") gizliliğinize önem vermektedir. Bu gizlilik politikası, uygulamamızı ("Uygulama") kullandığınızda bilgilerinizi nasıl topladığımız, kullandığımız ve koruduğumuz hakkında sizi bilgilendirir.
            
            1. Bilgi Toplama
            Uygulamamız, kişisel olarak tanımlanabilir herhangi bir bilgi (PII) toplamaz.
            
            Girdiğiniz tüm kelime verileri, yalnızca sizin cihazınızdaki yerel Core Data veritabanında saklanır. Bu verilere biz veya üçüncü taraflar erişemez.
            
            2. Bilgi Kullanımı
            Verileriniz yalnızca Uygulamanın temel işlevlerini (kelime öğrenme, test) sağlamak için kullanılır.
            
            3. Veri Paylaşımı
            Verileriniz cihazınızdan ayrılmadığı için, hiçbir verinizi üçüncü taraflarla paylaşmayız.            
            """
        )
    }
    
    func deleteAllData() {
        manager.deleteEverything()
    }
}
