import Testing
@testable import CoreAPI
import Foundation
import Alamofire

@Suite("NetworkManager Tests")
@MainActor
struct NetworkManagerTests {
    
    let sut: NetworkManager<MockEndpoint>
    let sahteSession: Session
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        sahteSession = Session(configuration: configuration)
        sut = NetworkManager<MockEndpoint>(session: sahteSession)
    }

    @Test("Resolves true data")
    func test_successful_request() async throws {
        
        MockURLProtocol.requestHandler = { request in
            let sahteJSON = """
            { "id": "1", "name": "Ağaç" }
            """.data(using: .utf8)!
            
            let sahteResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (sahteResponse, sahteJSON)
        }
        
        let result = await withCheckedContinuation { continuation in
            sut.request(endpoint: MockEndpoint(), type: MockModel.self) { responseResult in
                continuation.resume(returning: responseResult)
            }
        }
        
        switch result {
        case .success(let model):
            #expect(model.name == "Ağaç")
            #expect(model.id == "1")
        case .failure(let error):
            Issue.record("Test hata verdi: \(error)")
        }
    }
}
