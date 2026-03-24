//
//  BookcasePacketsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.12.2025.
//

import Combine
import Foundation
import CoreAPI
import DTO

enum UIState {
    case success
    case loading
    case empty
    case error(String)
}

enum DownloadState: Equatable {
    case waiting
    case downloading
    case success
    case error(String)
}

protocol BookcasePacketsViewModelProtocol: ObservableObject {
    var libraries: Libraries? { get }
    var selectedLibrary: String? { get }
    var uiState: UIState { get }
    var downloadState: DownloadState { get }
    func selectLibrary(code: String)
    func refreshData()
    func downloadLibrary(model: Library)
}

class BookcasePacketsViewModel: BookcasePacketsViewModelProtocol {

    // MARK: - PROPERTIES

    @Published var libraries: Libraries? =  nil
    @Published var selectedLibrary: String? = nil
    @Published var uiState: UIState = .loading
    @Published var downloadState: DownloadState = .waiting
    let networkService: APIServiceProtocol
    let coreDataService: CoreDataManagerProtocol
    
    // MARK: - INIT
    
    init(networkService: APIServiceProtocol, dataManager: CoreDataManagerProtocol) {
        self.networkService = networkService
        self.coreDataService = dataManager
        refreshData()
    }
    
    // MARK: - HELPERS
    
    func selectLibrary(code: String) {
        selectedLibrary = code
    }
    
    func refreshData() {
        networkService.fetchLibraries { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                if let libraries = data.libraries {
                    if libraries.isEmpty {
                        self.uiState = .empty
                    }else {
                        self.libraries = data
                        self.selectedLibrary = data.libraries?.first?.sourceLanguage
                        self.uiState = .success
                    }
                }
            case .failure(let error):
                self.uiState = .error(error.message)
            }
        }
    }
    
    func downloadLibrary(model: Library) {
        downloadState = .downloading
        guard let path = model.id else {
            downloadState = .error("Dosya bulunamadı")
            return
        }
        networkService.fetchBookcaseRequest(values: GetBookcaseRequestModel(bookcaseID: path)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let requestResult):
                self.coreDataService.importBookcase(requestResult, contextType: .background) { result in
                    switch result {
                    case .success(let success):
                        self.downloadState = .success
                    case .failure(let failure):
                        switch failure {
                        case .alreadyExist:
                            self.downloadState = .error("Bu isim kullanılıyor. İsmini değiştir ya da silmelisin")
                        case .missingRequiredFields:
                            self.downloadState = .error("Bilinmeyen bir hata oluştu")
                        }
                    }
                }
            case .failure(let error):
                downloadState = .error(error.message)
            }
        }
    }
}
