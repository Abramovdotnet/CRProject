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
    private let gameEventsBus: GameEventsBusService
    private var cancellables = Set<AnyCancellable>()
    private let locationReader: LocationReader
    private let vampireReader: NPCReader
    private var locationEventsService: LocationEventsService!
    
    init(gameTime: GameTimeService, 
         vampireNatureRevealService: VampireNatureRevealService,
         gameEventsBus: GameEventsBusService = DependencyManager.shared.resolve(),
         locationReader: LocationReader = DependencyManager.shared.resolve(),
         vampireReader: NPCReader = DependencyManager.shared.resolve()) {
        self.gameTime = gameTime
        self.vampireNatureRevealService = vampireNatureRevealService
        self.gameEventsBus = gameEventsBus
        self.locationReader = locationReader
        self.vampireReader = vampireReader
        
        // Initialize locationEventsService after all properties are set
        self.locationEventsService = LocationEventsService(
            gameEventsBus: gameEventsBus,
            vampireNatureRevealService: vampireNatureRevealService,
            gameStateService: self
        )
        
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
        DebugLogService.shared.log("Changing location to ID: \(locationId)", category: "Location")
        
        // Try to find and set the new location
        let newLocation = try LocationReader.getLocation(by: locationId)
        DebugLogService.shared.log("Found new location: \(newLocation.name)", category: "Location")
        
        // Update current scene
        currentScene = newLocation
        DebugLogService.shared.log("Current scene set to: \(currentScene?.name ?? "None")", category: "Location")
        
        // Update related locations
        updateRelatedLocations(for: locationId)
        
        // Advance time when changing location
        gameTime.advanceTime()
        gameEventsBus.addSystemMessage("Player entered \(currentScene?.name ?? "").")
    }
    
    private func updateRelatedLocations(for locationId: UUID) {
        DebugLogService.shared.log("GameStateService updating related locations for ID: \(locationId)", category: "Location")
        
        // Get parent location
        parentScene = LocationReader.getParentLocation(for: locationId)
        DebugLogService.shared.log("Parent scene: \(parentScene?.name ?? "None")", category: "Location")
        
        // Get child locations
        childScenes = LocationReader.getChildLocations(for: locationId)
        DebugLogService.shared.log("Child scenes count: \(childScenes.count)", category: "Location")
        for scene in childScenes {
            DebugLogService.shared.log("Child scene: \(scene.name)", category: "Location")
        }
        
        // Get sibling locations
        siblingScenes = LocationReader.getSiblingLocations(for: locationId)
        DebugLogService.shared.log("Sibling scenes count: \(siblingScenes.count)", category: "Location")
        for scene in siblingScenes {
            DebugLogService.shared.log("Sibling scene: \(scene.name)", category: "Location")
        }
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
        
        if player?.bloodMeter.currentBlood ?? 0 <= 30 {
            gameEventsBus.addDangerMessage(message: "* I feel huge lack of blood!*")
        }
        
        // Update NPC sleeping states
        locationEventsService.updateNPCSleepingState(scene: scene, isNight: gameTime.isNightTime)
        
        // Generate and broadcast a location event
        if let eventText = locationEventsService.generateEvent(scene: scene, isNight: gameTime.isNightTime) {
            locationEventsService.broadcastEvent(eventText)
        }
    }
    
    private func handleSafeTimeAdvanced() {
        guard let scene = currentScene else { return }
        
        // Reduce awareness for nearest scenes by 5
        for scene in siblingScenes {
            vampireNatureRevealService.decreaseAwareness(for: scene.id, amount: 5)
        }
        
        // Update NPC sleeping states
        locationEventsService.updateNPCSleepingState(scene: scene, isNight: gameTime.isNightTime)
        
        // Generate and broadcast a location event
        if let eventText = locationEventsService.generateEvent(scene: scene, isNight: gameTime.isNightTime) {
            locationEventsService.broadcastEvent(eventText)
        }
    }
    
    private func endGame() {
        self.showEndGame = true
    }
}
