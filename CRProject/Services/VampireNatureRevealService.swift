import Foundation
import Combine

extension Notification.Name {
    static let exposed = Notification.Name("exposed")
}

class VampireNatureRevealService: ObservableObject, GameService {
    private var awarenessLevel: Float = 0.0
    private let awarenessPublisher = PassthroughSubject<Int, Never>()
    private let gameEventsBus: GameEventsBusService
    
    static var shared: VampireNatureRevealService = DependencyManager.shared.resolve()
    
    init(gameEventsBus: GameEventsBusService = DependencyManager.shared.resolve()) {
        self.gameEventsBus = gameEventsBus
    }
    
    var exposedPublisher: AnyPublisher<Int, Never> {
        awarenessPublisher
            .filter { [weak self] sceneId in
                self?.getAwareness() ?? 0 >= 100
            }
            .eraseToAnyPublisher()
    }
    
    func getAwareness() -> Float {
        return awarenessLevel
    }
    
    func increaseAwareness(amount: Float) {
        awarenessLevel = min(awarenessLevel + amount, 100.0)
        
        if awarenessLevel >= 100 {
            NotificationCenter.default.post(name: .exposed, object: nil)
        }
        
        if awarenessLevel > 70 {
            gameEventsBus.addDangerMessage(message: "* People almost discovered me!")
        }
    }
    
    func decreaseAwareness(amount: Float) {
        awarenessLevel = max(awarenessLevel - amount, 0.0)
    }
} 
