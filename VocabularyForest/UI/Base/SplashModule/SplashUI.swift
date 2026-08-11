//
//  SplashUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import SwiftUI

struct SplashUI: View {
    
    // MARK: PROPERTIES
    
    @State var isActive: Bool = false
    @ObservedObject var viewModel: SplashViewModel
    
    // MARK: VIEWS

    var body: some View {
        ZStack {
            if(self.isActive){
                MainView()
            }else {
                Image("splash-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.width * 2 / 3, maxHeight: UIScreen.main.bounds.height * 2 / 3)
            }
        }.ignoresSafeArea().frame(maxWidth: .infinity,maxHeight: .infinity).trackScreen(.splash)
            .onAppear {
                guard !isActive else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.default) {
                        isActive = true
                    }
                }
            }
    }
}

#Preview {
    //SplashUI(viewModel: <#SplashViewModel#>)
}
