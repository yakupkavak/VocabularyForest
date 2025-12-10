//
//  SettingsUI.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 18.10.2025.
//
import SwiftUI

struct SettingsUI: View {
    
    // MARK: - PROPERTIES
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingDeleteAlert = false
    
    // MARK: - VIEW

    var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Bildirimler")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.top)

                VStack(alignment: .leading) {
                    Toggle("Kelime Bildirimleri", isOn: $viewModel.notificationsEnabled).onTapGesture {
                        viewModel.handleNotificationToggleChange()
                    }
                    Button("Bildirim Ayarlarını Aç") {
                        viewModel.openAppSettings()
                    }.tint(.logoGreen)
                }
                .padding()
                .background(Color.backgroundSystem)
                .cornerRadius(10)
                
                Text("Açık bırakırsanız, kelime tekrarı için günlük hatırlatıcılar alırsınız. İzin vermediyseniz, bu ayar sizden izin isteyecektir.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider()

                Text("Hakkında")
                    .font(.callout)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        viewModel.openAppStoreReview()
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
                .background(Color.backgroundSystem)
                .cornerRadius(10)
                
                Divider()

                Text("Tehlikeli Alan")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                Button("Tüm Verileri Sıfırla") {
                    showingDeleteAlert = true
                }
                .padding()
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
        .alert("Tüm Veriler Silinsin mi?", isPresented: $showingDeleteAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Sil", role: .destructive) {
                viewModel.deleteAllData()
            }
        } message: {
            Text("Bu işlem geri alınamaz. Tüm kitaplıklarınız ve kelimeleriniz kalıcı olarak silinecektir.")
        }
        .sheet(item: $viewModel.sheetContent) { content in
            PolicySheetView(content: content)
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
    SettingsUI()
}
