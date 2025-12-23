//
//  MockBookcasePacketsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation
import Combine

class MockBookcasePacketsViewModel: BookcasePacketsViewModelProtocol {
    
    // MARK: - PROPERTIES
    
    @Published var libraries: Libraries?
    @Published var error: String?
    @Published var selectedLibrary: String? = nil

    // Test senaryolarını yönetmek için init
    init(libraries: Libraries? = .mock, error: String? = nil) {
        self.libraries = libraries
        self.error = error
        
        // MARK: OTOMATİK SEÇİM EKLEMESİ
        // Eğer mock veri geldiyse, listenin ilk elemanını otomatik seçili yap
        if let firstLib = libraries?.libraries?.first {
            self.selectedLibrary = firstLib.sourceLanguage
        }
    }
    
    // MARK: - PROTOCOL METHODS
    
    func selectLibrary(code: String) {
        selectedLibrary = code
    }
    
    func refreshData() {
        print("Mock refresh data called.")
    }
    
    // Ekstra test metodları
    func triggerError() {
        self.libraries = nil
        self.error = "İnternet bağlantısı koptu (Mock Error)"
    }
    
    func triggerLoading() {
        self.libraries = nil
        self.error = nil
    }
}
