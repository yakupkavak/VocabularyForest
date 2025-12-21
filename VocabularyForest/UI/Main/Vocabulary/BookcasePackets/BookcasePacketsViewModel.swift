//
//  BookcasePacketsViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.12.2025.
//

import Combine
import Foundation

protocol BookcasePacketsViewModelProtocol: ObservableObject {
    func getBookcaseList()
    func downloadBookcase()
}

class BookcasePacketsViewModel: BaseViewModel {
    
}
