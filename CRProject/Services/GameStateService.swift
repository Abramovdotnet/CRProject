import Foundation

class GameStateService: ObservableObject, GameService {
    @Published private(set) var currentScene: Scene?
    private let gameTime: GameTimeService
    private let vampireNatureRevealService: VampireNatureRevealService
    
    init(gameTime: GameTimeService, vampireNatureRevealService: VampireNatureRevealService) {
        self.gameTime = gameTime
        self.vampireNatureRevealService = vampireNatureRevealService
        
        // Subscribe to time advancement
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimeAdvanced),
            name: .timeAdvanced,
            object: nil
        )
    }
    
    func setCurrentScene(_ scene: Scene) {
        self.currentScene = scene
    }
    
    @objc private func handleTimeAdvanced() {
        guard let scene = currentScene,
              !scene.isIndoor,
              !gameTime.isNightTime else { return }
        
        vampireNatureRevealService.increaseAwareness(for: scene.id, amount: 10.0)
    }
} 
