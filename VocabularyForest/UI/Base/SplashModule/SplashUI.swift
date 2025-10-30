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
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var bookcaseRouter: BookcaseRouter
    @EnvironmentObject private var createBookRouter: CreateBookRouter

    // MARK: VIEWS

    var body: some View {
        ZStack {
            if(self.isActive){
                MainView()
            }else {
                Image("splash-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
            }
        }.ignoresSafeArea().frame(maxWidth: .infinity,maxHeight: .infinity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.default) {
                        isActive.toggle()
                    }
                }
            }
    }
}

#Preview {
    SplashUI()
}
