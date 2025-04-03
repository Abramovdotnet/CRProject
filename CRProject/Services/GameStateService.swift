import Foundation
import Combine

enum GameStateError: Error {
    case locationNotFound
    case invalidLocation
}

class GameStateService : ObservableObject, GameService{
    @Published private(set) var currentScene: Scene?
    @Published private(set) var player: Player?
    @Published var parentScene: Scene?
    @Published var childScenes: [Scene] = []
    @Published var siblingScenes: [Scene] = []
    @Published var showEndGame: Bool = false
    
    private let gameTime: GameTimeService
    private let vampireNatureRevealService: VampireNatureRevealService
    private var cancellables = Set<AnyCancellable>()
    private let locationReader: LocationReader
    private let vampireReader: NPCReader
    
    init(gameTime: GameTimeService, vampireNatureRevealService: VampireNatureRevealService,
         locationReader: LocationReader = DependencyManager.shared.resolve(),
         vampireReader: NPCReader = DependencyManager.shared.resolve()) {
        self.gameTime = gameTime
        self.vampireNatureRevealService = vampireNatureRevealService
        self.locationReader = locationReader
        self.vampireReader = vampireReader
        
        // Subscribe to time advancement notifications
        NotificationCenter.default
            .publisher(for: .timeAdvanced)
            .sink { [weak self] _ in
                self?.handleTimeAdvanced()
            }
            .store(in: &cancellables)
        
        // Subscribe to time advancement notifications
        NotificationCenter.default
            .publisher(for: .safeTimeAdvanced)
            .sink { [weak self] _ in
                self?.handleSafeTimeAdvanced()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: .exposed)
            .sink { [weak self] _ in
                self?.endGame()
            }
            .store(in: &cancellables)
    }
    
    func setPlayer(_ player: Player) {
        self.player = player
    }
    
    func getPlayer() -> Player? {
        return player
    }
    
    func changeLocation(to locationId: UUID) throws {
        // Try to find and set the new location
        let newLocation = try LocationReader.getLocation(by: locationId)
        
        // Update current scene
        currentScene = newLocation
        
        // Update related locations
        updateRelatedLocations(for: locationId)
        
        // Advance time when changing location
        gameTime.advanceTime()
    }
    
    private func updateRelatedLocations(for locationId: UUID) {
        // Get parent location
        parentScene = LocationReader.getParentLocation(for: locationId)
        
        // Get child locations
        childScenes = LocationReader.getChildLocations(for: locationId)
        
        // Get sibling locations
        siblingScenes = LocationReader.getSiblingLocations(for: locationId)
    }
    
    private func handleTimeAdvanced() {
        guard let scene = currentScene else { return }
        
        // If current scene is indoor and it's not night time, increase awareness
        if scene.isIndoor && !gameTime.isNightTime {
            vampireNatureRevealService.increaseAwareness(for: scene.id, amount: 10)
            
            // Increase awareness for nearest scenes by 5 if current scene is indoor
            if scene.isIndoor {
                for nearScene in siblingScenes {
                    vampireNatureRevealService.increaseAwareness(for: nearScene.id, amount: 5)
                }
            }
        }
        
        // Reduce awareness for nearest scenes by 5
        for scene in siblingScenes {
            vampireNatureRevealService.decreaseAwareness(for: scene.id, amount: 5)
        }
        
        // Reduce player blood pool
        player?.bloodMeter.useBlood(5)
    }
    
    private func handleSafeTimeAdvanced() {
        guard let scene = currentScene else { return }
        
        // Reduce awareness for nearest scenes by 5
        for scene in siblingScenes {
            vampireNatureRevealService.decreaseAwareness(for: scene.id, amount: 5)
        }
    }
    
    private func endGame() {
        self.showEndGame = true
    }
}
