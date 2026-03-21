//
//  GameInfoUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.12.2025.
//

import SwiftUI

struct GameInfoModel {
    let title: String
    let image: String
    let description: String
}

let gameInfoText: [GameInfoModel] = [
    GameInfoModel(title: String(localized: "Orman Hakkında"), image: "foresttanitim0",description: String(localized: "Ormanına hoşgeldin! Görevleri tamamlayarak ormanına hayat katabilirsin. Toprağın zamanla kuruyacaktır, bunun için yağmur yağdırmayı unutma!")),
    GameInfoModel(title: String(localized: "Sorular Hakkında"), image: "foresttanitim3",description: String(localized: "Kelimelerin kısa ve uzun hafıza olarak ikiye ayrılmış durumda. Bir kelimeyi rekabet modunda bildiğinde uzun hafızana geçiyor. Ama unutma, bir hafta içerisinde hatırlatıcı modu ile tekrarlamazsan kısa hafızana geçecek!")),
    GameInfoModel(title: String(localized: "Yağmur Hakkında"), image: "foresttanitim1",description: String(localized: "Görevleri tamamlayarak yağmur taneleri toplayıp, hazneni doldurduğunda ekranında belirecek butona tıklayarak yağmur yağdırabilirsin.")),
    GameInfoModel(title: String(localized: "Canlılar Hakkında"),image: "foresttanitim0",description: String(localized: "Bitkilerin sağlıksız bir toprakta kuruyacaktır, hayvanların ise hareket edemeyecekler.."))
]

struct GameInfoUI: View {
    
    // MARK: - PROPERTIES
    @Binding var showForestPopUp: Bool
    @State private var currentPage = 0
    
    // MARK: - UI
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<gameInfoText.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey(gameInfoText[index].title))
                            .modifier(TitleBackground()).padding()
                        Image(gameInfoText[index].image).resizable().scaledToFill().frame(maxWidth: min(UIScreen.main.bounds.width * 0.75 ,400), maxHeight: 150).cornerRadius(20)
                        Spacer()
                        Text(LocalizedStringKey(gameInfoText[index].description))
                            .foregroundStyle(.white)
                            .font(.system(size: 13, weight: .medium))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .padding(12)
        .background(Color.brown.opacity(0.95))
        .frame(maxWidth: min(UIScreen.main.bounds.width * 0.8 ,400), maxHeight: 480)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("brown300"), lineWidth: 4)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                showForestPopUp = false
            } label: {
                Image("close_button")
                    .resizable()
                    .frame(maxWidth: 36, maxHeight: 36)
                    .offset(x: 12, y: -12)
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
        .zIndex(4.0)
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = .white
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        }
    }
}

#Preview {
    ZStack {
        Color.green.ignoresSafeArea()
        GameInfoUI(showForestPopUp: .constant(true))
    }
}
