import Foundation
import Combine

class VampireNatureRevealService: GameService {
    private var awarenessLevels: [UUID: Float] = [:]
    private let awarenessPublisher = PassthroughSubject<UUID, Never>()
    
    var exposedPublisher: AnyPublisher<UUID, Never> {
        awarenessPublisher
            .filter { [weak self] sceneId in
                self?.getAwareness(for: sceneId) ?? 0 >= 100
            }
            .eraseToAnyPublisher()
    }
    
    func getAwareness(for sceneId: UUID) -> Float {
        return awarenessLevels[sceneId] ?? 0.0 // Default minimum awareness
    }
    
    func increaseAwareness(for sceneId: UUID, amount: Float) {
        let currentAwareness = getAwareness(for: sceneId)
        let newAwareness = min(currentAwareness + amount, 100.0)
        awarenessLevels[sceneId] = newAwareness
        
        if newAwareness >= 100 {
            awarenessPublisher.send(sceneId)
        }
    }
    
    func decreaseAwareness(for sceneId: UUID, amount: Float) {
        let currentAwareness = getAwareness(for: sceneId)
        let newAwareness = max(currentAwareness - amount, 10.0)
        awarenessLevels[sceneId] = newAwareness
    }
} 
