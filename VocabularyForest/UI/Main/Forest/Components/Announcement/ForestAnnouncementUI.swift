//
//  ForestAnnouncementUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 29.03.2026.
//

import SwiftUI

struct ForestAnnouncementUI: View {
    
    // MARK: - PROPERTIES
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var isVisible: Bool
    var onClick: (AnnouncementTypeModel) -> Void
    
    private var responsivePadding: CGFloat {
        horizontalSizeClass == .regular ? 32 : 16
    }
    private var columns: [GridItem] {
        
        return [GridItem(.flexible(), spacing: responsivePadding + 12),
                GridItem(.flexible(), spacing: responsivePadding + 12)
        ]
    }
    
    private let announcements: [AnnouncementItem] = [
        AnnouncementItem(title: String(localized: "Tasks"), image: .dailyTaskIcon, type: .tasks),
        AnnouncementItem(title: String(localized: "Daily Reward"), image: .weeklyTaskIcon, type: .dailyReward),
        AnnouncementItem(title: String(localized: "Daily Spin"), image: .dailySpinIcon, type: .dailySpin),
        AnnouncementItem(title: String(localized: "Adventure Road"), image: .adventureRoadIcon, type: .adventureRoad)
    ]
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { geometry in
            let geometryWidth = geometry.size.width
            let cellWidthMultipler = 0.2
            GamePopUpContainer(title: "Macera Panosu", onClose: {isVisible.toggle()}, screenWidth: geometryWidth) {
                LazyVGrid(columns: columns, spacing: responsivePadding) {
                    ForEach(announcements) { model in
                        AnnouncementCellUI(
                            model: model,
                            width: geometryWidth * cellWidthMultipler
                        ).onTapGesture {
                            onClick(model.type)
                            isVisible = false
                        }
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct AnnouncementCellUI: View {
    
    let model: AnnouncementItem
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            Image(model.image).resizable().scaledToFit().frame(width: width, height: width)
            Text(model.title).foregroundStyle(.white).multilineTextAlignment(.center).frame(width: width, height: width * 0.6)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 18)
        .background(.white.opacity(0.15))
        .borderShape(radius: 20)
    }
}

#Preview {
    ForestAnnouncementUI(isVisible: .constant(true), onClick: { _ in
        print("yakup")
    })
}
