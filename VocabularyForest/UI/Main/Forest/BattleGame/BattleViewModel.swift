//
//  BattleViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 23.11.2025.
//

// BattleViewModel.swift

import SwiftUI
import Combine

protocol BattleViewModelOutputProcotol: AnyObject {
    func startRain()
    func stopRain()
}

class BattleViewModel: ObservableObject {
    
    weak var output: BattleViewModelOutputProcotol?

}
