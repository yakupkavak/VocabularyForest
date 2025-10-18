//
//  BaseViewModel.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 4.10.2025.
//

import Foundation
import Combine

class BaseViewModel: ObservableObject {
    /*
    func getThrowableDataCall<T>(
        dataCall: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onLoading: @escaping () -> Void,
        onError: @escaping (Error?) -> Void
        
    ) {
        Task {
            do {
                DispatchQueue.main.async { onLoading() }
                let result = try await dataCall()
                DispatchQueue.main.async {
                    onSuccess(result)
                }
            } catch {
                DispatchQueue.main.async {
                    onError(error)
                }
            }
        }
    }
    
    func getDataCall<T>(
        dataCall: @escaping () async -> Resource<T>,
        onSuccess: @escaping (T?) -> Void,
        onLoading: @escaping () -> Void,
        onError: @escaping (Error?) -> Void
        
    ) {
        Task {
            DispatchQueue.main.async { onLoading() }
            let result = await dataCall()
            
            DispatchQueue.main.async {
                switch result.status {
                case .success:
                    onSuccess(result.data)
                case .loading:
                    onLoading()
                case .error:
                    onError(result.error)
                }
            }
        }
    }*/
}
