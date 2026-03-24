import Foundation

public typealias DC = DependencyContainer

public protocol DCResolve {
    func resolve<Value>(type: DependencyContainerResolvingType, for interface: Value.Type) -> Value
}

public protocol DCRegister {
    func register(type: DependencyContainerRegistrationType, for interface: Any.Type)
}

public final class DependencyContainer {
    
    // MARK: - PUBLIC PROPERTIES
    
    @MainActor public static let shared = DependencyContainer()
    
    // MARK: - PRIVATE PROPERTIES

    private var singleInstanceDependencies: [ObjectIdentifier: AnyObject] = [:]
    private var closureBasedDependecies: [ObjectIdentifier: () -> Any] = [:]
    private let dependencyAccessQueue = DispatchQueue(
        label: "com.yakupkavak.dependency.container.access.queue",
        attributes: .concurrent
    )
    
    // MARK: - INIT

    private init() { }
        
}

extension DependencyContainer: DCResolve {
    public func resolve<Value>(type: DependencyContainerResolvingType, for interface: Value.Type) -> Value {
        var value: Value!
        dependencyAccessQueue.sync {
            let objectIdentifier = ObjectIdentifier(interface)
            switch type {
            case .singleInstance:
                guard let singleInstanceDependency = singleInstanceDependencies[objectIdentifier] as? Value else {
                    fatalError("Couldn't retrive a dependency for the given \(interface)")
                }
                value = singleInstanceDependency
            case .closureBased:
                guard let closure = closureBasedDependecies[objectIdentifier],
                        let closureBasedDependency = closure() as? Value else {
                    fatalError("Couldn't retrive a dependency for the given \(interface)")
                }
                value = closureBasedDependency
            }
        }
        return value
    }
}

extension DependencyContainer: DCRegister {
    public func register(type: DependencyContainerRegistrationType, for interface: Any.Type) {
        dependencyAccessQueue.sync(flags: .barrier) {
            let objectIdentifier = ObjectIdentifier(interface)
            switch type {
            case .singleInstance(let instance):
                singleInstanceDependencies[objectIdentifier] = instance
            case .closureBased(let closure):
                closureBasedDependecies[objectIdentifier] = closure
            }
        }
    }
}
