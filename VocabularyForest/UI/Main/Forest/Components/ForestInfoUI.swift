//
//  ForestInfoUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.12.2025.
//

import SwiftUI

struct ForestInfoUI: View {
    
    // MARK: - PROPERTIES
    
    var forestModel: ForestStatusModel?
    var onClose: () -> Void
    
    // MARK: - UI VIEW
    
    var body: some View {
        GamePopUpContainer(title: "Doğa Dengesi", onClose: onClose) {
            VStack(spacing: 24) {
                if let forestModel {
                    HStack {
                        Image(systemName: "drop").resizable().scaledToFit().frame(width: 32).foregroundStyle(.brown300).overlay{
                            Image(systemName: "drop.fill").resizable().scaledToFit().foregroundStyle(.brown300).mask {
                                GeometryReader { geo in
                                    Rectangle().frame(height: geo.size.height * CGFloat(forestModel.rainValue) / CGFloat(50)
                                )}
                            }
                        }
                        Text("Doluluk oranı \(forestModel.rainValue) / 50").foregroundStyle(.white).font(.system(size: 16))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "circle.circle.fill").resizable().scaledToFit().frame(width: 32).foregroundStyle(.yellow)
                        Text("Altın: \(forestModel.gold)").foregroundStyle(.white).font(.system(size: 16))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "leaf.fill").resizable().scaledToFit().frame(width: 32).foregroundStyle(.logoGreen)
                        Text("Toprak sağlığı: %\(forestModel.landHealthPercentage)").foregroundStyle(.white).font(.system(size: 16))
                        Spacer()
                    }
                }else {
                    Text("Beklenmedik hata").foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    ForestInfoUI(forestModel: ForestStatusModel(rainValue: 10, landHealthPercentage: 10, landStatus: true, gold: 210), onClose: {
        print("yakup")
    })
}
