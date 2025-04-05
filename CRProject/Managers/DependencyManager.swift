import Foundation

final class DependencyManager {
    static let shared = DependencyManager()
    
    private var services: [ObjectIdentifier: AnyObject] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Registration
    
    func register<T: GameService>(_ service: T) {
        lock.lock()
        defer { lock.unlock() }
        services[ObjectIdentifier(T.self)] = service
        DebugLogService.shared.log("📦 Registered service: \(T.self)", category: "Dependency")
    }
    
    func register<T: GameService>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        services[ObjectIdentifier(T.self)] = factory()
        DebugLogService.shared.log("📦 Registered service: \(T.self)", category: "Dependency")
    }
    
    // MARK: - Resolution
    
    func resolve<T: GameService>() -> T {
        lock.lock()
        defer { lock.unlock() }
        
        guard let service = services[ObjectIdentifier(T.self)] as? T else {
            fatalError("Service of type \(T.self) is not registered.")
        }
        return service
    }
    
    func resolveOptional<T: GameService>() -> T? {
        lock.lock()
        defer { lock.unlock() }
        return services[ObjectIdentifier(T.self)] as? T
    }
    
    // MARK: - Removal
    
    func remove<T: GameService>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        services.removeValue(forKey: ObjectIdentifier(T.self))
        DebugLogService.shared.log("🗑️ Removed service: \(T.self)", category: "Dependency")
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        services.removeAll()
        DebugLogService.shared.log("🧹 Cleared all services", category: "Dependency")
    }
}
