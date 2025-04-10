import Foundation
import Combine

extension Notification.Name {
    static let exposed = Notification.Name("exposed")
}

class VampireNatureRevealService: ObservableObject, GameService {
    private var awarenessLevels: [Int: Float] = [:]
    private let awarenessPublisher = PassthroughSubject<Int, Never>()
    private let gameEventsBus: GameEventsBusService
    
    init(gameEventsBus: GameEventsBusService = DependencyManager.shared.resolve()) {
        self.gameEventsBus = gameEventsBus
    }
    
    var exposedPublisher: AnyPublisher<Int, Never> {
        awarenessPublisher
            .filter { [weak self] sceneId in
                self?.getAwareness(for: sceneId) ?? 0 >= 100
            }
            .eraseToAnyPublisher()
    }
    
    func getAwareness(for sceneId: Int) -> Float {
        return awarenessLevels[sceneId] ?? 0.0 // Default minimum awareness
    }
    
    func increaseAwareness(for sceneId: Int, amount: Float) {
        let currentAwareness = getAwareness(for: sceneId)
        let newAwareness = min(currentAwareness + amount, 100.0)
        awarenessLevels[sceneId] = newAwareness
        
        if newAwareness >= 100 {
            awarenessPublisher.send(sceneId)
            NotificationCenter.default.post(name: .exposed, object: nil)
        }
        
        if newAwareness > 70 {
            gameEventsBus.addDangerMessage(message: "* People almost discovered me!")
        }
    }
    
    func decreaseAwareness(for sceneId: Int, amount: Float) {
        let currentAwareness = getAwareness(for: sceneId)
        let newAwareness = max(currentAwareness - amount, 0.0)
        awarenessLevels[sceneId] = newAwareness
    }
} 
