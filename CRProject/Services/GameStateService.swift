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
    
    static let shared: GameStateService = DependencyManager.shared.resolve()
    
    private let gameTime: GameTimeService
    private let vampireNatureRevealService: VampireNatureRevealService
    private let gameEventsBus: GameEventsBusService
    private var cancellables = Set<AnyCancellable>()
    private let locationReader: LocationReader
    private let vampireReader: NPCReader
    //private var npcPopulationService: NPCPopulationService!
    private var npcManager = NPCInteractionManager.shared
    
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
        
        // Initialize LocationEventsService using DependencyManager
        DependencyManager.shared.register(LocationEventsService(gameEventsBus: gameEventsBus, vampireNatureRevealService: vampireNatureRevealService, gameStateService: self))
        
        // Initialize NPCPopulationService using DependencyManager
        /*DependencyManager.shared.register(NPCPopulationService(gameStateService: self, gameEventsBus: gameEventsBus))
        self.npcPopulationService = DependencyManager.shared.resolve()*/
        
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
    
    func changeLocation(to locationId: Int) throws {
        DebugLogService.shared.log("Changing location to ID: \(locationId)", category: "Location")
        
        // Try to find and set the new location
        let newLocation = try LocationReader.getLocation(by: locationId)
        DebugLogService.shared.log("Found new location: \(newLocation.name)", category: "Location")
        
        // Update current scene
        currentScene = newLocation
        DebugLogService.shared.log("Current scene set to: \(currentScene?.name ?? "None")", category: "Location")
        
        // Update related locations
        updateRelatedLocations(for: locationId)
        
        npcManager.selectedNPC = nil
        
        // Advance time when changing location
        gameTime.advanceTime()
    }
    
    private func updateRelatedLocations(for locationId: Int) {
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
    
    func handleTimeAdvanced() {
        NPCBehaviorService.shared.updateActivity()
        advanceWorldState()
        
        // Reduce player blood pool
        player?.bloodMeter.useBlood(5)
        
        // Reset selection if npc left location
        guard let scene = currentScene else { return }
        
        if npcManager.selectedNPC != nil {
            if !scene.hasCharacter(with: npcManager.selectedNPC!.id) {
                npcManager.selectedNPC = nil
            }
        }
    }
    
    func advanceWorldState() {
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
        
        if player?.bloodMeter.currentBlood ?? 0 <= 30 {
            gameEventsBus.addDangerMessage(message: "* I feel huge lack of blood!*")
        }
    }
    
    private func handleSafeTimeAdvanced() {
        // Reduce awareness for nearest scenes by 5
        for scene in siblingScenes {
            vampireNatureRevealService.decreaseAwareness(for: scene.id, amount: 5)
        }
        
        // Reset selection if npc left location
        guard let scene = currentScene else { return }
        
        if npcManager.selectedNPC != nil {
            if !scene.hasCharacter(with: npcManager.selectedNPC!.id) {
                npcManager.selectedNPC = nil
            }
        }
    }
    
    private func endGame() {
        self.showEndGame = true
    }
    
    var isNightTime: Bool {
        return gameTime.isNightTime
    }
}
