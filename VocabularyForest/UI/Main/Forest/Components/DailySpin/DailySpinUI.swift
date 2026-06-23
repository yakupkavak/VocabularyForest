//
//  DailySpinUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 5.04.2026.
//

import SwiftUI
import YKSpinWheel
import Combine

// MARK: - CONSTANTS & MODELS

private extension DailySpinUI {
    static let backgroundHeight = 0.7
}

// MARK: - UI

struct DailySpinUI: View {
    
    // MARK: - PROPERTIES

    @StateObject var controller: YKSpinController
    @Binding var isVisible: Bool
    @Binding var nextSpinTime: Date?
    
    var onRewardClaimed: (SpinModel) -> Void
    
    init(
        models: [SpinModel],
        isVisible: Binding<Bool>,
        nextSpinTime: Binding<Date?>,
        onRewardClaimed: @escaping (SpinModel) -> Void
    ) {
        self._isVisible = isVisible
        self._nextSpinTime = nextSpinTime
        self.onRewardClaimed = onRewardClaimed
        _controller = StateObject(wrappedValue: YKSpinController(models: models))
    }
    
    // MARK: - BODY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                mainCard(size: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - UI COMPONENTS

private extension DailySpinUI {
    
    func mainCard(size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Image("krem")
                .resizable()
                .frame(width: size.width * 0.96, height: size.height * DailySpinUI.backgroundHeight)
            
            VStack(spacing: 0) {
                titleView
                    .padding(.top, size.height * 0.04)
                
                headerSection(size: size)
                    .padding(.top, size.height * 0.015)
                
                spinWheelSection(size: size)
                    .padding(.top, size.height * 0.03)
                
                actionSection
                    .padding(.top, size.height * 0.03)
            }
        }
    }
    
    var titleView: some View {
        Text("Daily Spin")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 3)
    }
    
    func headerSection(size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            HStack {
                Spacer()
                Text("Play everyday and get additional bonuses")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 2)
                Spacer()
            }.offset(y: size.height * 0.01)
            
            Button {
                isVisible = false
            } label: {
                Image("close_button_gold")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width * 0.07)
                    .foregroundStyle(goldGradient)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            .offset(x: -size.width * 0.13, y: size.height * 0.01)
        }
        .frame(width: size.width * 0.96)
    }
    
    func spinWheelSection(size: CGSize) -> some View {
        let radius = min(size.width, size.height) / 2
        
        return YKSpinWheel(
            controller: controller,
            center: {
                Image("daliy_spin_center").resizable()
            },
            wheelTopPointer: {
                Image("çarkıfelek_ok").resizable().scaleEffect(y: -1)
            }
        )
        .ykPieceThinSliceAngleThreshold(60)
        .ykPointerHeight(radius * 0.2)
        .ykPointerWidth(radius * 0.2)
        .ykPointerOffset(-radius * 0.065)
        .frame(width: size.width * 0.68, height: size.height * 0.4)
    }
    
    var actionSection: some View {
        Group {
            if let nextSpinTime {
                Text("Wait until \n \(String(describing: nextSpinTime.toFriendlyRemaintime()))")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange.opacity(0.95))
                    .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
            } else {
                Button {
                    Task {
                        if let rewardModel = await controller.startSpin(spinTime: 4, spinTurns: 5) {
                            onRewardClaimed(rewardModel)
                        }
                    }
                } label: {
                    Text("Start Spin")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.title.opacity(0.95))
                        .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - PREVIEW

#Preview {
    DailySpinPreviewWrapper()
}

struct DailySpinPreviewWrapper: View {
    @State private var models: [SpinModel] = [] // Buraya kendi model tipini (örn: DailySpinModel) yazarsın
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                DailySpinUI(
                    models: models, // spinService.dailySpinList yerine bu state'i veriyoruz
                    isVisible: .constant(true),
                    nextSpinTime: .constant(nil),
                    onRewardClaimed: { _ in }
                )
            } else {
                ProgressView("Çark Yükleniyor...")
            }
        }
        .task {
            let jsonString = """
            {
              "id": "daily_spin_rewards_config_v2",
              "items": [
                {
                  "id": 1,
                  "weight": 3,
                  "textColorHex": "#FFFFFF",
                  "backgroundHexes": [
                    "#FFD700",
                    "#FF8C00"
                  ],
                  "text": {
                    "tr": "Altın Sandık",
                    "en": "Gold Chest",
                    "es": "Cofre de Oro",
                    "fr": "Coffre d'Or",
                    "de": "Goldtruhe",
                    "pt": "Baú de Ouro"
                  },
                  "reward": {
                    "id": "reward-gold-chest",
                    "type": "chest",
                    "category": "gold",
                    "rewardCount": 1,
                    "chestId": "chest-gold",
                    "displayName": {
                      "tr": "Altın Sandık",
                      "en": "Gold Chest",
                      "es": "Cofre de Oro",
                      "fr": "Coffre d'Or",
                      "de": "Goldtruhe",
                      "pt": "Baú de Ouro"
                    }
                  }
                },
                {
                  "id": 2,
                  "weight": 1.8,
                  "textColorHex": "#FFFFFF",
                  "backgroundHexes": [
                    "#32CD32",
                    "#006400"
                  ],
                  "text": {
                    "tr": "Doğa",
                    "en": "Nature",
                    "es": "Naturaleza",
                    "fr": "Nature",
                    "de": "Natur",
                    "pt": "Natureza"
                  },
                  "reward": {
                    "id": "reward-nature-chest",
                    "type": "chest",
                    "category": "nature",
                    "rewardCount": 1,
                    "chestId": "chest-nature",
                    "displayName": {
                      "tr": "Doğa Sandığı",
                      "en": "Nature Chest",
                      "es": "Cofre de Naturaleza",
                      "fr": "Coffre Nature",
                      "de": "Naturtruhe",
                      "pt": "Baú da Natureza"
                    }
                  }
                },
                {
                  "id": 3,
                  "weight": 0.8,
                  "textColorHex": "#FFFFFF",
                  "backgroundHexes": [
                    "#8B4513",
                    "#A0522D"
                  ],
                  "text": {
                    "tr": "Antik",
                    "en": "Antique",
                    "es": "Antiguo",
                    "fr": "Antique",
                    "de": "Antik",
                    "pt": "Antigo"
                  },
                  "reward": {
                    "id": "reward-antique-chest",
                    "type": "chest",
                    "category": "antique",
                    "rewardCount": 1,
                    "chestId": "chest-antique",
                    "displayName": {
                      "tr": "Antik Sandık",
                      "en": "Antique Chest",
                      "es": "Cofre Antiguo",
                      "fr": "Coffre Antique",
                      "de": "Antike Truhe",
                      "pt": "Baú Antigo"
                    }
                  }
                },
                {
                  "id": 4,
                  "weight": 0.6,
                  "textColorHex": "#FFFFFF",
                  "backgroundHexes": [
                    "#00FFFF",
                    "#4682B4"
                  ],
                  "text": {
                    "tr": "Elmas",
                    "en": "Diamond",
                    "es": "Diamante",
                    "fr": "Diamant",
                    "de": "Diamant",
                    "pt": "Diamante"
                  },
                  "reward": {
                    "id": "reward-diamond-chest",
                    "type": "chest",
                    "category": "diamond",
                    "rewardCount": 1,
                    "chestId": "chest-diamond",
                    "displayName": {
                      "tr": "Elmas Sandık",
                      "en": "Diamond Chest",
                      "es": "Cofre de Diamante",
                      "fr": "Coffre Diamant",
                      "de": "Diamanttruhe",
                      "pt": "Baú de Diamante"
                    }
                  }
                },
                {
                  "id": 5,
                  "weight": 5,
                  "textColorHex": "#000000",
                  "backgroundHexes": [
                    "#FFFACD",
                    "#FFD700"
                  ],
                  "text": {
                    "tr": "450 Altın",
                    "en": "450 Gold",
                    "es": "450 Oro",
                    "fr": "450 Or",
                    "de": "450 Gold",
                    "pt": "450 Ouro"
                  },
                  "reward": {
                    "id": "reward-gold-resource",
                    "type": "standart",
                    "category": "gold",
                    "rewardCount": 450,
                    "assetName": "gold_icon",
                    "displayName": {
                      "tr": "450 Altın",
                      "en": "450 Gold",
                      "es": "450 Oro",
                      "fr": "450 Or",
                      "de": "450 Gold",
                      "pt": "450 Ouro"
                    },
                    "imageSource": "local",
                    "localImageName": "gold_icon"
                  }
                },
                {
                  "id": 6,
                  "weight": 6,
                  "textColorHex": "#FFFFFF",
                  "backgroundHexes": [
                    "#87CEFA",
                    "#1E90FF"
                  ],
                  "text": {
                    "tr": "20 Damla",
                    "en": "20 Drops",
                    "es": "20 Gotas",
                    "fr": "20 Gouttes",
                    "de": "20 Tropfen",
                    "pt": "20 Gotas"
                  },
                  "reward": {
                    "id": "reward-water-resource",
                    "type": "standart",
                    "category": "water",
                    "rewardCount": 20,
                    "assetName": "water_icon",
                    "displayName": {
                      "tr": "20 Yağmur Damlası",
                      "en": "20 Rain Drops",
                      "es": "20 Gotas de Lluvia",
                      "fr": "20 Gouttes de Pluie",
                      "de": "20 Regentropfen",
                      "pt": "20 Gotas de Chuva"
                    },
                    "imageSource": "local",
                    "localImageName": "water_icon"
                  }
                }
              ]
            }
            """
            
            let data = jsonString.data(using: .utf8)!
            if let remoteList = try? JSONDecoder().decode(RemoteDailySpinListModel.self, from: data) {
                let coreData = CoreDataManager()
                let assetManager = OfflineAssetManager()
                let network = APIService()
                let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
                
                let spinService = DailySpinService(
                    forestManager: forestData,
                    rewardRepository: RewardRepository(
                        assetManager: assetManager,
                        apiService: network,
                        chestRepository: ChestRepository(assetManager: assetManager, apiService: network),
                        forestManager: forestData
                    )
                )
                
                try? await spinService.convertRemoteToDailySpinList(list: remoteList)
                self.models = spinService.dailySpinList
                self.isLoaded = true
            }
        }
    }
}
