//
//  VocabularyForestTests.swift
//  VocabularyForestTests
//
//  Created by Yakup Kavak on 20.03.2026.
//

import Testing
@testable import DependencyContainer

struct DependecyContainerTests{
    
    @Test("Register and resolve should return save value")
    @MainActor func test_single_instance_registration_and_resolving() {
        let instance = SingleInstanceImplementation()
        DC.shared.register(type: .singleInstance(instance), for: SingleInstanceProtocol.self)
        
        let resolvedInstance = DC.shared.resolve(type: .singleInstance, for: SingleInstanceProtocol.self)
        let ayniNesneMi = (instance === resolvedInstance)
        #expect(ayniNesneMi)
    }
    
    @Test
    @MainActor func test_closure_based_registration_and_resolving() {
        let closure: () -> ClosureBasedProtocol = {
            ClosureBasedImplementation()
        }
        DC.shared.register(type: .closureBased(closure), for: ClosureBasedProtocol.self)
        
        let resolved = DC.shared.resolve(type: .closureBased, for: ClosureBasedProtocol.self)
        #expect(resolved is ClosureBasedImplementation)
    }
    
    @Test
    @MainActor func test_closure_based_dependency_which_depends_on_another() {
        let closure: () -> ClosureBasedProtocol = {
            ClosureBasedImplementation()
        }
        DC.shared.register(type: .closureBased(closure), for: ClosureBasedProtocol.self)
        let anotherDependencyClosure: () -> AnotherDependencyProtocol = {
            let service = DC.shared.resolve(type: .closureBased, for: ClosureBasedProtocol.self)
            return AnotherDependencyImplementation(service: service)
        }
        DC.shared.register(type: .closureBased(anotherDependencyClosure), for: AnotherDependencyProtocol.self)
        let resolvedAnotherDependency = DC.shared.resolve(type: .closureBased, for: AnotherDependencyProtocol.self)
        
        #expect(resolvedAnotherDependency is AnotherDependencyImplementation)
    }
}
