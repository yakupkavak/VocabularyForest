//
//  FirebaseBootstrap.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 17.07.2026.
//

import FirebaseCore
import Foundation

enum FirebaseBootstrap {
    
    static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else { return }
        
        guard
            let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: plistPath)
        else {
            assertionFailure("GoogleService-Info.plist app bundle içinde bulunamadı. Target → Copy Bundle Resources kontrol et.")
            return
        }
        
        FirebaseApp.configure(options: options)
    }
}
