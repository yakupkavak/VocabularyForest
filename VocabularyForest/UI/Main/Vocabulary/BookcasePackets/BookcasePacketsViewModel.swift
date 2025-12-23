//
//  BookcasePacketsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.12.2025.
//

import Combine
import Foundation

enum UIState {
    case success
    case loading
    case empty
    case error(String)
}

protocol BookcasePacketsViewModelProtocol: ObservableObject {
    var libraries: Libraries? { get }
    var selectedLibrary: String? { get }
    var uiState: UIState { get }
    func selectLibrary(code: String)
    func refreshData()
}

class BookcasePacketsViewModel: BookcasePacketsViewModelProtocol {

    // MARK: - PROPERTIES

    @Published var libraries: Libraries? =  nil
    @Published var selectedLibrary: String? = nil
    @Published var uiState: UIState = .loading
    let networkService: APIServiceProtocol
    
    // MARK: - INIT
    
    init(networkService: APIServiceProtocol) {
        self.networkService = networkService
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
    
    func downloadBookcase(bookcaseID: String) {
        networkService.fetchBookcaseRequest(values: GetBookcaseRequestModel(bookcaseID: bookcaseID)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let result):
                print("\(result)")
                // TODO KITAPLIK OLUŞTUR
            case .failure(let error):
                uiState = .error(error.localizedDescription)
            }
        }
    }
}
