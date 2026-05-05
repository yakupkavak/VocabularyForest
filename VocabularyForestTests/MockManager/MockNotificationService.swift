//
//  MockNotificationService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.03.2026.
//

import Testing
import UserNotifications
import UIKit
@testable import VocabularyForest

@Suite("Bildirim Yöneticisi (NotificationManager) Testleri", .tags(.system))
@MainActor // NotificationManager @MainActor ile işaretli olduğu için testleri de MainActor'de koşturuyoruz
final class NotificationManagerTests {
    
    // Test Edilecek Sistem (SUT)
    let sut: NotificationManager
    
    init() {
        // Her testten önce sıfır bir NotificationManager yaratılır
        sut = NotificationManager()
        // NOT: init() içinde checkNotificationStatus() çağrıldığı için
        // ilk yaratılışta sistemin mevcut iznini alır (Genelde test ortamında false döner).
    }
    
    // MARK: - SAĞLIK BİLDİRİMLERİ TESTLERİ
    
    @Test("Geçersiz süre (60 saniyeden az) girildiğinde sağlık bildirimi kurulmamalı")
    func testScheduleHealthNotification_InvalidTime() async {
        // GIVEN
        let targetValue = 50
        let invalidTime: TimeInterval = 30 // 60'tan küçük
        
        // WHEN
        sut.scheduleHealthNotification(targetValue: targetValue, timeInterval: invalidTime)
        
        // THEN
        // Bildirimin merkeze eklenip eklenmediğini kontrol etmek için bekleyen bildirimleri çekiyoruz
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        let hasOurNotification = pendingRequests.contains { $0.identifier == "health_limit_50" }
        #expect(hasOurNotification == false, "🚨 60 saniyeden kısa süre verildiğinde bildirim kurulmamalıydı!")
    }
    
    @Test("Geçerli değerlerde sağlık bildirimi doğru başlık ve içerikle kurulmalı")
    func testScheduleHealthNotification_ValidTimeAndValue() async {
        // GIVEN
        // Test öncesi ortalığı temizleyelim ki eski bildirimler testi yanıltmasın
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let targetValue = 10
        let validTime: TimeInterval = 120 // 2 dakika
        
        // WHEN
        sut.scheduleHealthNotification(targetValue: targetValue, timeInterval: validTime)
        
        // THEN
        // Bildirimin sisteme kaydedilmesi asenkron olabilir, ufak bir bekleme (sleep) koyuyoruz
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye
        
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        // Eklenen bildirimi bul
        guard let request = pendingRequests.first(where: { $0.identifier == "health_limit_10" }) else {
            Issue.record("🚨 health_limit_10 ID'li bildirim merkeze eklenemedi!")
            return
        }
        
        // İçeriği kontrol et
        #expect(request.content.title == "🚨 KRİTİK DURUM!", "Yanlış başlık eklendi!")
        #expect(request.content.body.contains("10"), "İçerikte %10 ibaresi geçmiyor!")
        
        // Trigger kontrolü
        guard let trigger = request.trigger as? UNTimeIntervalNotificationTrigger else {
            Issue.record("🚨 Trigger tipi yanlış (Zaman bazlı olmalıydı)!")
            return
        }
        #expect(trigger.timeInterval == 120, "Bildirim süresi yanlış ayarlandı!")
    }
    
    @Test("Sağlık bildirimleri iptal edildiğinde sistemden silinmeli")
    func testCancelHealthNotifications() async {
        // GIVEN: Önce bir bildirim kuralım
        sut.scheduleHealthNotification(targetValue: 20, timeInterval: 3600)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // WHEN: İptal fonksiyonunu çağıralım
        sut.cancelHealthNotifications()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // THEN: Bekleyen bildirimler arasında olmamalı
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let hasNotification = pendingRequests.contains { $0.identifier == "health_limit_20" }
        
        #expect(hasNotification == false, "🚨 Bildirimler başarıyla silinemedi!")
    }
    
    // MARK: - KELİME ÖĞRENME BİLDİRİMLERİ TESTLERİ
    
    @Test("Kelime bildirimi doğru içerikle sisteme eklenmeli")
    func testCreateNotification_WordAndMeaning() async {
        // GIVEN
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let testBookID = "book_123"
        let learningWord = "Apple"
        let meaningWord = "Elma"
        
        // WHEN: (Description ve Example boş ise askWordAndMeaning çalışır)
        sut.createNotification(
            bookId: testBookID,
            learningWord: learningWord,
            meaningWord: meaningWord,
            description: "",
            example: ""
        )
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // THEN
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard let request = pendingRequests.first(where: { $0.identifier == testBookID }) else {
            Issue.record("🚨 Kelime bildirimi oluşturulamadı!")
            return
        }
        
        #expect(request.content.subtitle == "Apple")
        #expect(request.content.body == "Meaning: Elma")
        
        // Trigger'ın Calendar bazlı olduğunu kontrol edelim (her gün tekrar eden)
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            Issue.record("🚨 Kelime bildirimi takvim (Calendar) bazlı kurulmalıydı!")
            return
        }
        #expect(trigger.repeats == true, "Kelime bildirimi tekrarlanabilir (repeats) olmalı!")
        
        // Saatin 8 ile 22 arasında rastgele atandığını doğrulayalım
        if let hour = trigger.dateComponents.hour {
            #expect((8...22).contains(hour), "Bildirim saati mesai saatleri dışında!")
        }
    }
    
    @Test("Belirli bir kelime bildirimi silinebilmeli")
    func testDeleteSpecificNotification() async {
        // GIVEN
        let testBookID = "delete_test_id"
        sut.createNotification(bookId: testBookID, learningWord: "Dog", meaningWord: "Köpek", description: "", example: "")
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // WHEN
        sut.deleteNotification(bookId: testBookID)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // THEN
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let stillExists = pendingRequests.contains { $0.identifier == testBookID }
        #expect(stillExists == false, "🚨 Kelime bildirimi silinemedi!")
    }
}
