//
//  WaveView.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.10.2025.
//

import SwiftUI

//MARK: Learning Descriptions
/*
 Circle(), Rectangle() gibi şekiller Shape protokolünü uygular. Biz de kendi custom shapemizi yani görünümümüzü oluşturuyoruz.
 Current point curvenin anlık konumunu belirtiyor.
 Offset ile currentPoint'i animasyona dahil ediyoruz
 */

struct LiquidShape: Shape {
    
    //MARK: Properties
    var offset: CGSize
    var currentPoint: CGFloat
    var animatableData: AnimatablePair<CGSize.AnimatableData, CGFloat> {
        get {
            return AnimatablePair(offset.animatableData, currentPoint)
        }
        set {
            offset.animatableData = newValue.first
            currentPoint = newValue.second
        }
    }
    //Dalgamızın üst sınırı nereden başlayacak y ekseninde
    let thresholdCurve = CGFloat(80)
    //Dalgamız en son nerede bitebilecek y ekseninde
    let endCurve = CGFloat(180)
    
    //MARK: View
    func path(in rect: CGRect) -> Path {
        return Path { path in
            //Ofset sola kayıyorsa yani negatif ise genişliğe ekliyoruz
            let width = rect.width + (-offset.width > 0 ? offset.width : 0)
            
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            
            let from = thresholdCurve + offset.height + (-offset.width)
            path.move(to: CGPoint(x: rect.width, y: from > thresholdCurve ? thresholdCurve : from))
            
            var to = endCurve + (offset.height) + (-offset.width)
            to = to < endCurve ? endCurve : to
            
            let mid: CGFloat = thresholdCurve + ((to - thresholdCurve) / 2)
            
            path.addCurve(to: CGPoint(x: rect.width, y: to), control1: CGPoint(x: width - currentPoint, y: mid), control2: CGPoint(x: width - currentPoint, y: mid))
        }
    }
}
