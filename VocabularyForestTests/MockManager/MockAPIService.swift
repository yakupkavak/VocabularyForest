//
//  MockAPIService.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 13.06.2026.
//

@testable import VocabularyForest
import Alamofire
import Foundation
import DTO

class MockAPIService: APIServiceProtocol {
    
    // MARK: - Call Trackers
    
    var didCallFetchBookcaseRequest = false
    var didCallFetchLibraries = false
    var didCallFetchImage = false
    var didCallFetchZip = false
    
    // MARK: - Captured Arguments
    
    var capturedBookcaseValues: GetBookcaseRequestModel?
    var capturedImageValues: GetImageRequestModel?
    var capturedZipValues: GetZipRequestModel?
    
    // MARK: - Stubs (Return Values)
    
    var stubbedBookcaseResult: BookcaseRequestResult!
    var stubbedLibrariesResult: LibrariesResult!
    var stubbedImageResult: ImageResult!
    var stubbedZipResult: ZipResult!
    
    // MARK: - Init
    
    init() {}
    
    // MARK: - APIServiceProtocol Methods
    
    func fetchBookcaseRequest(values: GetBookcaseRequestModel, completion: @escaping (BookcaseRequestResult) -> Void) {
        didCallFetchBookcaseRequest = true
        capturedBookcaseValues = values
        
        if let result = stubbedBookcaseResult {
            completion(result)
        }
    }
    
    func fetchLibraries(completion: @escaping (LibrariesResult) -> Void) {
        didCallFetchLibraries = true
        
        if let result = stubbedLibrariesResult {
            completion(result)
        }
    }
    
    func fetchImage(values: GetImageRequestModel, completion: @escaping (ImageResult) -> Void) {
        didCallFetchImage = true
        capturedImageValues = values
        
        if let result = stubbedImageResult {
            completion(result)
        }
    }
    
    func fetchZip(values: GetZipRequestModel, completion: @escaping (ZipResult) -> Void) {
        didCallFetchZip = true
        capturedZipValues = values
        
        if let result = stubbedZipResult {
            completion(result)
        }
    }
}
