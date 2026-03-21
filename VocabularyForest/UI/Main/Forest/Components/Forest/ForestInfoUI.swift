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
        GamePopUpContainer(title: String(localized: "Doğa Dengesi"), onClose: onClose) {
            VStack(spacing: 24) {
                if let forestModel {
                    HStack {
                        Image(systemName: "drop").resizable().scaledToFit().frame(width: 32).foregroundStyle(.blue).overlay{
                            Image(systemName: "drop.fill").resizable().scaledToFit().foregroundStyle(.blue).mask {
                                GeometryReader { geo in
                                    Rectangle().frame(height: geo.size.height * CGFloat(forestModel.rainValue) / CGFloat(50)
                                )}
                            }
                        }
                        VStack(alignment: .leading) {
                            Text("Doluluk oranı \(forestModel.rainValue) / 50").foregroundStyle(.white).font(.system(size: 16))
                            Text("Ormanına can vermek için doldurmalısın.").foregroundStyle(.white).font(.system(size: 12))
                        }
                        Spacer()
                    }
                    HStack {
                        Image( "gold_icon").resizable().scaledToFit().frame(width: 32).foregroundStyle(.yellow)
                        VStack(alignment: .leading) {
                            Text("Altın: \(forestModel.gold)").foregroundStyle(.white).font(.system(size: 16))
                            Text("Gelecek güncelleme ile mağazada kullanabileceksin.").foregroundStyle(.white).font(.system(size: 12))
                        }
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "leaf.fill").resizable().scaledToFit().frame(width: 32).foregroundStyle(.logoGreen)
                        VStack(alignment: .leading) {
                            Text("Toprak sağlığı: %\(forestModel.landHealthPercentage)").foregroundStyle(.white).font(.system(size: 16))
                            Text("Mutlu hayvan ve bitkiler için olmazsa olmaz.").foregroundStyle(.white).font(.system(size: 12))
                        }
                        Spacer()
                    }
                }else {
                    Text("Beklenmedik hata").foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

#Preview {
    ForestInfoUI(forestModel: ForestStatusModel(rainValue: 10, landHealthPercentage: 10, landStatus: true, gold: 210), onClose: {
        print("yakup")
    })
}
