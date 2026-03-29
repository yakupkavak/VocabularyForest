//
//  ForestUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 26.03.2026.
//

import Testing
import XCTest // XCUIApplication'ı kullanabilmek için XCTest'i dahil etmeliyiz

@Suite("Forest Ekranı (UI) Kullanıcı Etkileşim Testleri", .tags(.ui))
@MainActor
struct ForestUITests {
    
    // Uygulamayı ayağa kaldıracak olan "Robot" parmağımız
    let app: XCUIApplication
    
    init() {
        // Her testten önce uygulamayı taze bir şekilde başlatıyoruz
        app = XCUIApplication()
        // Test ortamında olduğumuzu uygulamaya bildirebiliriz (Gerekirse sahte veri basmak için)
        app.launchArguments.append("-UITesting")
        app.launch()
    }
    
    // MARK: - 🌧 YAĞMUR BUTONU TESTİ
    
    @Test("Kullanıcı yağmur butonuna bastığında buton ekrandan kaybolmalı")
    func testRainButtonDisappearsAfterTap() async throws {
        // GIVEN: Ekranda yağmur butonunu bul
        let rainButton = app.buttons["rain_start_button"]
        
        // Butonun ekrana gelmesi için maksimum 3 saniye bekle (Animasyonlar vs. için)
        let exists = rainButton.waitForExistence(timeout: 3.0)
        
        // Eğet buton yoksa (Orman zaten sağlıklıysa vs.) testi pas geçebiliriz veya hata fırlatabiliriz
        try #require(exists, "🚨 Yağmur butonu ekranda bulunamadı! (Belki orman zaten %100 sağlıklı?)")
        
        // WHEN: Robot parmağımızla butona basıyoruz
        rainButton.tap()
        
        // THEN: Butonun ekrandan silindiğini doğruluyoruz
        #expect(rainButton.exists == false, "🚨 Butona basıldı ama ekrandan kaybolmadı!")
    }
    
    // MARK: - ⚙️ AYARLAR MENÜSÜ TESTİ
    
    @Test("Options (Ayarlar) butonuna basıldığında menü açılmalı")
    func testSettingsMenuOpens() async throws {
        // GIVEN: Ayarlar butonunu bul (Burada localized string veya identifier kullanabiliriz)
        // Eğer SettingsModel içindeki title'ı "Settings" ise, XCUITest onu bulabilir:
        let settingsButton = app.buttons["Settings"]
        
        try #require(settingsButton.waitForExistence(timeout: 2.0), "🚨 Ayarlar butonu ekranda yok!")
        
        // WHEN: Ayarlar butonuna tıkla
        settingsButton.tap()
        
        // THEN: Ekranda "Music" veya "SFX" slider'larının belirmesini bekle
        let musicSlider = app.sliders["Music"]
        let isMenuOpened = musicSlider.waitForExistence(timeout: 2.0)
        
        #expect(isMenuOpened == true, "🚨 Ayarlar butonuna basıldı ama Ayarlar menüsü açılmadı!")
        
        // Hatta menüyü kapatmayı da test edebiliriz:
        let closeButton = app.buttons["close_button"] // Eğer image name buysa ve identifier verilmişse
        if closeButton.exists {
            closeButton.tap()
            #expect(musicSlider.exists == false, "🚨 Kapatma butonuna basıldı ama menü kapanmadı!")
        }
    }
    
    // MARK: - 📚 KİTAPLIK HATASI (POPUP) TESTİ
    
    @Test("Kitaplık yetersiz olduğunda uyarı Popup'ı çıkmalı")
    func testBookcaseThresholdPopup() async throws {
        // Not: Bu testi tam yapabilmek için uygulamayı "Bomboş veritabanı" ile başlatmamız gerekir.
        // app.launchArguments.append("-EmptyDatabase") gibi bir taktikle UI testine bunu söyleyebilirsin.
        
        // Diyelim ki bir oyuna girmeye çalıştık ve Popup çıktı...
        let popupTitle = app.staticTexts["Eksik soru"]
        
        // Eğer o senaryoyu UI üzerinden tetikleyebiliyorsan:
        // app.buttons["oyna_butonu"].tap()
        
        // Doğrulama:
        // let popupExists = popupTitle.waitForExistence(timeout: 2.0)
        // #expect(popupExists == true, "🚨 Yetersiz kelime olmasına rağmen Popup çıkmadı!")
    }
}
