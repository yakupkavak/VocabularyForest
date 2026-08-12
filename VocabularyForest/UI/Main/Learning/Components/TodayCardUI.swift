//
//  TodayCardUı.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 3.11.2025.
//

import SwiftUI

struct CardFront : View {
    
    // MARK: PROPERTIES

    let meaningWord: String
    let exampleSentence: String
    let descriptionSentence: String
    let width : CGFloat
    let height : CGFloat
    let onClick: () -> Void
    private var meaningFontSize: CGFloat {
        width * 0.07
    }
    private var descriptionFontSize: CGFloat {
        width * 0.06
    }
    private var exampleFontSize: CGFloat {
        width * 0.06
    }
    @Binding var degree : Double

    // MARK: VIEW

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
            .fill(Color(hex: "#022601"))
            .frame(width: width, height: height)
            .shadow(color: .gray, radius: 2, x: 0, y: 0)
            .overlay(alignment: .topTrailing) {
                Button {
                    onClick()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24)
                        .foregroundStyle(Color.brown700)
                }
                .contentShape(Rectangle())
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            
            VStack(spacing: 8){
                if !meaningWord.isEmpty {
                    Text(meaningWord).font(.system(size: meaningFontSize)).frame(maxWidth: width * 2 / 3).padding(10).background(.thickMaterial.opacity(0.2)).clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    ).overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.ultraThinMaterial.opacity(0.5), lineWidth: 1.5)
                    }.foregroundStyle(Color(hex:"#F2CB05")).lineLimit(2).zIndex(2.0)
                }
                if !descriptionSentence.isEmpty {
                    FrontCardText(text: descriptionSentence, width: width, fontSize: descriptionFontSize).zIndex(2.0)
                }
                if !exampleSentence.isEmpty {
                    FrontCardText(text: exampleSentence, width: width, fontSize: exampleFontSize).zIndex(2.0)
                }
            }
            
        }.rotation3DEffect(Angle(degrees: degree), axis: (x: 0, y: 1, z: 0))
    }
}

private extension CardFront {
    
    struct FrontCardText: View {
        
        // MARK: - PROPERTIES
        
        var text: String
        var width: CGFloat
        var fontSize: CGFloat
        
        var body: some View {
            Text(text).font(.system(size: fontSize)).frame(maxWidth: width * 3 / 4).padding(10).background(.thickMaterial.opacity(0.2)).clipShape(
                RoundedRectangle(cornerRadius: 16)
            ).overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.ultraThinMaterial.opacity(0.5), lineWidth: 1.5)
            }.foregroundStyle(Color(hex:"#F2CB05"))
        }
    }
}

struct CardBack : View {
    
    // MARK: PROPERTIES

    let learningWord: String
    let width: CGFloat
    let height: CGFloat
    private var titleFontSize: CGFloat {
        height * 0.07
    }
    @Binding var degree : Double
    
    // MARK: VIEW

    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex:"#022601").opacity(0.7), lineWidth: 3)
                .frame(width: width, height: height)

            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#8C7A20").opacity(0.2))
                .frame(width: width, height: height)
                .shadow(color: .gray, radius: 2, x: 0, y: 0)

            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#F2EEAE").opacity(0.7))
                .padding()
                .frame(width: width, height: height)

            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex:"#022601").opacity(0.7), lineWidth: 3)
                .padding()
                .frame(width: width, height: height)
            
            VStack{
                ZStack{
                    Image(systemName: "seal.fill")
                        .resizable()
                        .frame(width: width / 5, height: height / 6)
                        .foregroundColor(Color(hex: "#F2CB05").opacity(0.7))

                    Image(systemName: "seal")
                        .resizable()
                        .frame(width: width * 6 / 13, height: height * 5 / 13)
                        .foregroundColor(Color(hex: "#BFA004"))

                    Image(systemName: "seal")
                        .resizable()
                        .frame(width: width * 17 / 24, height: height * 13 / 24)
                        .foregroundColor(Color(hex: "#010D00").opacity(0.7))
                }.padding(.top, 8)
                    .accessibilityHidden(true)
                Text(learningWord.isEmpty ? String(localized: "Firstly create a book") : learningWord).font(.system(size: titleFontSize)).frame(maxWidth: width * 3 / 4).padding(10).zIndex(2.0).foregroundStyle(Color(hex: "#8C3027")).lineLimit(2).padding(.top, -12)
            }

        }.rotation3DEffect(Angle(degrees: degree), axis: (x: 0, y: 1, z: 0))

    }
}

struct TodayCardUI: View {
    
    // MARK: PROPERTIES
    
    @State var backDegree = 0.0
    @State var frontDegree = -90.0
    @State var isFlipped = false
    var width: CGFloat {
        get {
            height * 0.75
        }
    }
    var height: CGFloat
    let learningWord: String
    let meaningWord: String
    let exampleSentence: String
    let descriptionSentence: String
    let durationAndDelay : CGFloat = 0.3
    let onRefreshClick: () -> Void

    // MARK: FLIP FUNCTION
    
    func flipCard () {
        isFlipped = !isFlipped
        /// The 3D flip is purely visual; speak which side is now facing the user
        A11yAnnouncer.announce(String(localized: isFlipped ? "a11y_card_front" : "a11y_card_back"))
        if isFlipped {
            withAnimation(.linear(duration: durationAndDelay)) {
                backDegree = 90
            }
            withAnimation(.linear(duration: durationAndDelay).delay(durationAndDelay)){
                frontDegree = 0
            }
        } else {
            withAnimation(.linear(duration: durationAndDelay)) {
                frontDegree = -90
            }
            withAnimation(.linear(duration: durationAndDelay).delay(durationAndDelay)){
                backDegree = 0
            }
        }
    }
    
    // MARK: - VIEW
    
    var body: some View {
        ZStack {
            CardBack(
                learningWord: learningWord,
                width: width,
                height: height,
                degree: $backDegree
            )
            /// Both faces stay in the view tree; expose only the visible one
            .accessibilityHidden(isFlipped)
            CardFront(
                meaningWord: meaningWord,
                exampleSentence: exampleSentence,
                descriptionSentence: descriptionSentence,
                width: width,
                height: height,
                onClick: {
                    onRefreshClick()
                    flipCard()
                },
                degree: $frontDegree
            )
            .accessibilityHidden(!isFlipped)
        }
        .onTapGesture {
            flipCard()
        }
        .a11yTapButton(
            value: String(localized: isFlipped ? "a11y_card_front" : "a11y_card_back"),
            hint: String(localized: "a11y_flip_card_hint")
        )
    }
}

#Preview {
    TodayCardUI(height: 320, learningWord: "learning", meaningWord: "meaning", exampleSentence: "dscriptionfdsafdsafsadfsaddfasdfdsafadssadf", descriptionSentence: "dscriptionfdsafdsafsadfsaddasdfasfsafsadf", onRefreshClick: { })
}

extension Color {
    init(hex: String) {
        // 1. "#" veya "0x" gibi ön ekleri ve boşlukları temizle
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        // 2. Hex string'ini bir sayıya (UInt64) çevir
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        
        // 3. String'in uzunluğuna göre renkleri ve alfayı ayır (RRGGBBAA)
        switch hex.count {
        case 3: // RGB (12-bit) örn: "123" -> "112233"
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RRGGBB (24-bit) örn: "010D00"
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // RRGGBBAA (32-bit) örn: "010D00FF"
            (r, g, b, a) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // Geçersizse veya boşsa tam opak siyah yap
            (a, r, g, b) = (255, 0, 0, 0)
        }

        // 4. SwiftUI'ın 0.0-1.0 aralığındaki 'Double' formatına çevir
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
