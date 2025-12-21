//
//  BookcasePacketsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 21.12.2025.
//

import SwiftUI

struct BookcasePacketsUI<ViewModel>: View where ViewModel: BookcasePacketsViewModelProtocol {
    
    // MARK: - PROPERTIES
    
    @EnvironmentObject private var router: BookcaseRouter
    @StateObject private var viewModel: ViewModel
    
    // MARK: - INIT
    
    init(viewModel: @autoclosure @escaping () -> ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }
    
    // MARK: - UI
    
    var body: some View {
        Text("")
    }
}
