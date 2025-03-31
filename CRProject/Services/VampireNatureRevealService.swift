import Foundation

class VampireNatureRevealService: GameService {
    private let gameTime: GameTime
    private var sceneAwareness: [UUID: Float] = [:]
    private var lastVisitDays: [UUID: Int] = [:]
    
    init(gameTime: GameTime = DependencyManager.shared.resolve()) {
        self.gameTime = gameTime
    }
    
    func getAwareness(for sceneId: UUID) -> Float {
        return sceneAwareness[sceneId] ?? 0
    }
    
    func increaseAwareness(for sceneId: UUID, amount: Float = 20.0) {
        let currentAwareness = sceneAwareness[sceneId] ?? 0
        sceneAwareness[sceneId] = min(currentAwareness + amount, 100.0)
        lastVisitDays[sceneId] = gameTime.currentDay
    }
    
    func decreaseAwareness(for sceneId: UUID) {
        guard let lastVisit = lastVisitDays[sceneId] else { return }
        let daysSinceLastVisit = gameTime.currentDay - lastVisit
        
        if daysSinceLastVisit > 0 {
            let decreaseAmount = Float(daysSinceLastVisit) * 10.0
            let currentAwareness = sceneAwareness[sceneId] ?? 0
            sceneAwareness[sceneId] = max(currentAwareness - decreaseAmount, 10.0)
            lastVisitDays[sceneId] = gameTime.currentDay
        }
    }
    
    func updateAllScenes() {
        for sceneId in sceneAwareness.keys {
            decreaseAwareness(for: sceneId)
        }
    }
} 
