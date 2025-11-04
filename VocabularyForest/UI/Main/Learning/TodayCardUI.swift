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
    let width : CGFloat
    let height : CGFloat
    @Binding var degree : Double

    // MARK: VIEW

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#022601"))
                .frame(width: width, height: height)
                .shadow(color: .gray, radius: 2, x: 0, y: 0)

            VStack(spacing: 24){
                Image(systemName: "suit.club.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(hex: "#F2CB05"))
                
                Text(meaningWord).frame(maxWidth: 100).padding(10).background(.thickMaterial.opacity(0.5)).clipShape(
                    RoundedRectangle(cornerRadius: 16)
                ).overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.ultraThinMaterial.opacity(0.5), lineWidth: 1.5)
                }.zIndex(2.0).foregroundStyle(Color(hex:"#F2CB05"))
            }
           
        }.rotation3DEffect(Angle(degrees: degree), axis: (x: 0, y: 1, z: 0))
    }
}

struct CardBack : View {
    
    // MARK: PROPERTIES

    let learningWord: String
    let width : CGFloat
    let height : CGFloat
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
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color(hex: "#F2CB05").opacity(0.7))

                    Image(systemName: "seal")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color(hex: "#BFA004"))

                    Image(systemName: "seal")
                        .resizable()
                        .frame(width: 200, height: 200)
                        .foregroundColor(Color(hex: "#010D00").opacity(0.7))
                }
                Text(learningWord).frame(maxWidth: 100).padding(10).zIndex(2.0).foregroundStyle(Color(hex: "#8C3027"))
            }

        }.rotation3DEffect(Angle(degrees: degree), axis: (x: 0, y: 1, z: 0))

    }
}

struct TodayCardUI: View {
    
    // MARK: PROPERTIES
    
    @State var backDegree = 0.0
    @State var frontDegree = -90.0
    @State var isFlipped = false

    let width : CGFloat = 250
    let height : CGFloat = 325
    let durationAndDelay : CGFloat = 0.3

    // MARK: FLIP FUNCTION
    
    func flipCard () {
        isFlipped = !isFlipped
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
            CardFront(meaningWord: "öğrendim", width: width, height: height, degree: $frontDegree)
            CardBack(learningWord: "Uzumaki dattebayo", width: width, height: height, degree: $backDegree)
        }.onTapGesture {
            flipCard ()
        }
    }
}

#Preview {
    TodayCardUI()
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
