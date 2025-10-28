//
//  MemoryProgressBar.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 28.10.2025.
//

import SwiftUI

struct MemoryProgressBar: View {
    
    let percentage: Int
    let width: CGFloat
    private var progress: Double {
        Double(Double(percentage) / 100.0)
    }
    private var lineWidth: CGFloat {
        width / 5
    }
    private var textSize: CGFloat {
        width / 4.5
    }
    var body: some View {
        ZStack{
            Circle().stroke(lineWidth: lineWidth).foregroundStyle(.selectedButton.opacity(0.5))
            Circle().trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: .init(lineWidth: lineWidth,lineCap: .round, lineJoin: .round)).foregroundColor(.selectedButton)
                .rotationEffect(
                    Angle(degrees: 270.0)
                )
            
            // TODO: - LOCALIZE HERE
            
            Text("%\(percentage)").font(.system(size: textSize))
        }.frame(maxWidth: width)
    }
}

#Preview {
    MemoryProgressBar(percentage: 10, width: 50)
}
