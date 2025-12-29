//
//  MockBookcasePacketsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 22.12.2025.
//

import Foundation
import Combine

class MockBookcasePacketsViewModel: BookcasePacketsViewModelProtocol {
    var downloadState: DownloadState
    
    func downloadLibrary(model: Library) {
        print("model")
    }
    
    
    // MARK: - PROPERTIES
    
    @Published var libraries: Libraries?
    @Published var selectedLibrary: String? = nil
    @Published var uiState: UIState

    // Test senaryolarını yönetmek için init
    // Varsayılan olarak .success ve mock data ile başlar
    init(uiState: UIState = .success, libraries: Libraries? = .mock) {
        self.uiState = uiState
        self.libraries = libraries
        self.downloadState = .downloading
        // Eğer durum Success ise ve veri varsa otomatik seçim yap (Gerçek senaryodaki gibi)
        if case .success = uiState, let firstLib = libraries?.libraries?.first {
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
}
