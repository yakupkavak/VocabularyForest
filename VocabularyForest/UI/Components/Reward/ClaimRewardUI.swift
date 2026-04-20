//
//  ClaimRewardUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 20.04.2026.
//

import SwiftUI

struct ClaimRewardUI: View {
    
    // MARK: - PROPERTIES
    
    var reward: DailyBountyModel
    var onClaim: (QuestRewardModel) -> Void
    @State private var chestStatus: ChestStatus = .close
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            VStack {
                switch reward {
                case .standart(let model):
                    Image(model.rewardImage).resizable().scaledToFit().frame(width: width * 0.5)
                    Text(model.rewardName)
                case .chest(let model):
                    Image(model.getChestImage(status: chestStatus)).resizable().scaledToFit().frame(width: width * 0.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight:.infinity, alignment: .center)
            .background(RewardHelper.getBackgroundGradient(reward: reward))
        }
    }
}

#Preview {
    ClaimRewardUI(reward: .chest(model: .antique)) { reward in
        print(reward)
    }
}
