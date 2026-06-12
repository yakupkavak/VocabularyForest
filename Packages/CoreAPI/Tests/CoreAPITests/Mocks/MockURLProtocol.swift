//
//  MockURLProtocol.swift
//  CoreAPI
//
//  Created by Yakup Kavak on 12.06.2026.
//

import Foundation

@MainActor
class MockURLProtocol: URLProtocol {
    @MainActor static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { return }
        
        do {
            // İsteği yakaladık ve handler'a yolladık. Handler bize sahte bir response ve data verecek.
            let (response, data) = try handler(request)
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}
