//
//  TabBarController.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import Foundation
import Combine

final class TabBarController: ObservableObject{
    
    // MARK: - PROPERTIES
    
    @Published var isVisible = true
    
    // MARK: - FUCNTIONS

    func hideTabbar(){
        isVisible = false
    }
    
    func showTabbar(){
        isVisible = true
    }
}
