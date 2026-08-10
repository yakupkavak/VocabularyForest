//
//  BookcaseDeleteAlertExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 10.08.2026.
//

import SwiftUI

extension View {
    /// Asks for confirmation before a bookcase delete runs. The pending bookcase doubles as the
    /// presentation trigger, so clearing it is what dismisses the alert.
    func bookcaseDeleteConfirmation(
        pendingBookcase: Binding<BookcaseModel?>,
        onConfirm: @escaping (BookcaseModel) -> Void
    ) -> some View {
        alert(
            "Kitaplık silinsin mi?",
            isPresented: Binding(
                get: { pendingBookcase.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented { pendingBookcase.wrappedValue = nil }
                }
            ),
            presenting: pendingBookcase.wrappedValue
        ) { bookcase in
            Button("Vazgeç", role: .cancel) {
                pendingBookcase.wrappedValue = nil
            }
            Button("Sil", role: .destructive) {
                pendingBookcase.wrappedValue = nil
                onConfirm(bookcase)
            }
        } message: { bookcase in
            Text("\(bookcase.bookcaseName) kitaplığı ve içindeki tüm kelimeler kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
    }
}
