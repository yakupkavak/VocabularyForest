//
//  SettingsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//

import SwiftUI
import StoreKit
import GoogleSignInSwift
import AuthenticationServices

struct SettingsUI: View {
    
    // MARK: - PROPERTIES
    
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingDeleteAlert = false
    @State private var showNameEditAlert = false
    @State private var newUserName = ""
    @State private var showSignIn = false
    @Environment(\.requestReview) var requestReview
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var randomAnimal = getRandomAnimalModel().head

    // MARK: - VIEW

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Account")
                .font(.callout)
                .foregroundColor(.gray)
                .padding(.top)
                .padding(.top, -16)

            userHeader
            
            Divider()
            
            notificationView
            
            Divider()

            Text("Hakkında")
                .font(.callout)
                .foregroundColor(.gray)

            aboutPage
            
            Divider()

            Text("Tehlikeli Alan")
                .font(.callout)
                .foregroundColor(.gray)
            
            Button("Tüm Verileri Sıfırla") {
                showingDeleteAlert = true
            }
            .padding(.horizontal)
            .tint(.red)
            .cornerRadius(10)
            
            Text("Bu işlem tüm kitaplıklarınızı ve kelimelerinizi kalıcı olarak silecektir. Bu işlem geri alınamaz.")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.backgroundSystem.ignoresSafeArea())
        .navigationTitle("Ayarlar")
        .alert("Bir Sorun Oluştu", isPresented: $viewModel.showConflictError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.conflictErrorMsg)
        }
        .alert("Tüm Veriler Silinsin mi?", isPresented: $showingDeleteAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Sil", role: .destructive) {
                viewModel.deleteAllData()
            }
        } message: {
            Text("Bu işlem geri alınamaz. Tüm kitaplıklarınız ve kelimeleriniz kalıcı olarak silinecektir.")
        }
        .alert("Kullanıcı Adı", isPresented: $showNameEditAlert) {
            TextField("Yeni adınız", text: $newUserName)
            
            Button("Vazgeç", role: .cancel) { }
            
            Button("Kaydet") {
                let trimmedName = newUserName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    viewModel.updateUserName(name: trimmedName)
                }
            }
        } message: {
            Text("Lütfen yeni kullanıcı adınızı girin.")
        }
        .sheet(item: $viewModel.sheetContent) { content in
            PolicySheetView(content: content)
        }
        .fullScreenCover(isPresented: $showSignIn) {
            VStack {
                Color.clear.contentShape(Rectangle())
                            .ignoresSafeArea()
                            .onTapGesture {
                                showSignIn = false
                            }
                BottomSheet(title: nil, isVisible: $showSignIn) {
                    VStack {
                        GoogleSignInButton(scheme: .light, style: .standard, state: .normal) {
                            viewModel.signInGoogle()
                            showSignIn = false
                        }
                        SignInWithAppleButton(
                            .signIn,
                            
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                                AppleSignInManager.shared.requestAppleAuthorization(request)
                            },
                            
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    viewModel.signInApple(auth: authorization)
                                case .failure(let error):
                                    print("AppleAuthorization failed: \(error)")
                                }
                                showSignIn = false
                            }
                        )
                        Color.brown500
                        Spacer()
                    }
                }
                .frame(height: horizontalSizeClass == .regular ? 400 : 200)
            }
            .ignoresSafeArea()
            .presentationBackground(.clear)
            
        }
        .overlay {
            if viewModel.userHaveForestInFirebase,
               let local = viewModel.userLocalForest,
               let cloud = viewModel.firebaseForest {
                
                ForestConflictView(
                    localForest: local,
                    cloudForest: cloud,
                    onResolve: { source in
                        viewModel.resolveForestConflict(keep: source)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(100) 
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.userHaveForestInFirebase)
    }
}

private extension SettingsUI {
    
    @ViewBuilder
    var notificationView: some View {
        Text("Bildirimler")
            .font(.callout)
            .foregroundColor(.gray)
            .padding(.top)

        VStack(alignment: .leading) {
            Toggle("Kelime Bildirimleri", isOn: Binding(
                get: { viewModel.notificationsEnabled },
                set: { newValue in
                    viewModel.handleNotificationToggleChange()
                }
            ))
            Button("Bildirim Ayarlarını Aç") {
                viewModel.openAppSettings()
            }.tint(.logoGreen)
        }
        .padding(.horizontal)
        .background(Color.backgroundSystem)
        .cornerRadius(10)
        
        Text("Açık bırakırsanız, kelime tekrarı için günlük hatırlatıcılar alırsınız. İzin vermediyseniz, bu ayar sizden izin isteyecektir.")
            .font(.caption)
            .foregroundColor(.gray)
    }
    
    @ViewBuilder
    var aboutPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                requestReview()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow).frame(width: 50)
                    Text("Bize Puan Verin")
                }
            }
            Button {
                viewModel.showTermsOfUse()
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.logoBrown).frame(width: 50)
                    Text("Kullanım Koşulları")
                }
            }
            Button {
                viewModel.showPrivacyPolicy()
            } label: {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.logoGreen).frame(width: 50)
                    Text("Gizlilik Politikası")
                }
            }
        }
        .tint(.primary)
    }
    
    @ViewBuilder
    var userHeader: some View {
        if viewModel.userSignIn {
            HStack(spacing: 15) {
                Image(randomAnimal)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 30)
                    .foregroundColor(.logoGreen)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(viewModel.playerName)
                        Button {
                            newUserName = viewModel.playerName
                            showNameEditAlert = true
                        } label: {
                            Image(systemName: "pencil")
                        }

                    }
                    HStack(spacing: 4) {
                        Button {
                            viewModel.trySyncManuel()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.caption2)
                        }.foregroundStyle(.clickableText)
                        Text("Son eşitleme: \(viewModel.lastSyncDate)")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
                Spacer()
                Button {
                    viewModel.signOut()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .background(Color.backgroundSystem)
            .cornerRadius(12)
            
        } else {
            VStack(spacing: 20) {
                HStack {
                    Button {
                        showSignIn = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Hesaba Giriş Yap")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.logoGreen)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                    Image(systemName: "cloud.moon.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.logoBrown)
                }.padding(.horizontal)
                Text("Ormanını buluta kaydetmek için giriş yap.")
                    .frame(minWidth: 0, maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
            .background(Color.backgroundSystem)
            .cornerRadius(12)
        }
    }
}

private struct PolicySheetView: View {
    
    let content: PolicyContent
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content.text)
                    .padding()
            }
            .navigationTitle(content.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let coreData = CoreDataManager()
    let forestData = ForestDataManager(mainContext: coreData.viewContext, backgroundContext: coreData.backgroundContext)
    SettingsUI(
        viewModel: SettingsViewModel(
            notificationManager: NotificationManager(),
            coreDataManager: coreData,
            authManager: AuthManager(),
            syncManager: ForestSyncManager(),
            forestManager: forestData,
            playerManager: PlayerDataManager()
        )
    )
}
