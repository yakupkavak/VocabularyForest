//
//  SingleInstanceTestModels.swift
//  DependencyContainer
//
//  Created by Yakup Kavak on 21.03.2026.
//

protocol SingleInstanceProtocol: AnyObject {
    func sampleMethod()
}

final class SingleInstanceImplementation: SingleInstanceProtocol {
    func sampleMethod() {
        //left
    }
}

protocol ClosureBasedProtocol {
    func sampleMethod()
}

struct ClosureBasedImplementation: ClosureBasedProtocol {
    func sampleMethod() {
        //letf
    }
}

protocol AnotherDependencyProtocol {
    func anotherSampleMethod()
}

struct AnotherDependencyImplementation: AnotherDependencyProtocol {
    
    private let service: ClosureBasedProtocol
    
    init(service: ClosureBasedProtocol) {
        self.service = service
    }
    
    func anotherSampleMethod() {
        // left blank
    }
}
