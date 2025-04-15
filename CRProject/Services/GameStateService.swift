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
    
    func movePlayerThroughHideouts(to: HidingCell) {
        player?.hiddenAt = to
        
        if player?.hiddenAt != nil {
            npcManager.selectedNPC = nil
        }
    }
    
    func changeLocation(to locationId: Int) throws {
        DebugLogService.shared.log("Changing location to ID: \(locationId)", category: "Location")
        
        movePlayerThroughHideouts(to: .none)
        
        // Try to find and set the new location
        let newLocation = try LocationReader.getRuntimeLocation(by: locationId)
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
        player?.bloodMeter.useBlood(4)
        
        // Reset selection if npc left location
        guard let scene = currentScene else { return }
        
        if npcManager.selectedNPC != nil {
            if !scene.hasCharacter(with: npcManager.selectedNPC!.id) {
                npcManager.selectedNPC = nil
            }
        }
    }
    
    private func handleSafeTimeAdvanced() {
        NPCBehaviorService.shared.updateActivity()
        advanceWorldState(advanceSafe: true)
        
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
    
    func advanceWorldState(advanceSafe: Bool = false) {
        guard let scene = currentScene else { return }
        guard let player = player else { return }
        
        if player.hiddenAt != .none {
            vampireNatureRevealService.decreaseAwareness(for: scene.id, amount: 6)
        } else {
            if !gameTime.isNightTime {
                vampireNatureRevealService.increaseAwareness(for: scene.id, amount: 6)
            }
        }
        
        // Reduce awareness for nearest scenes by 5
        for scene in siblingScenes {
            vampireNatureRevealService.decreaseAwareness(for: scene.id, amount: 6)
        }
        
        var currentPlayerBlood = player.bloodMeter.currentBlood
        
        if currentPlayerBlood <= 30 {
            gameEventsBus.addDangerMessage(message: "* I feel huge lack of blood!*")
        }
        
        if currentPlayerBlood <= 10 {
            releasePlayerThirst()
        }
    }
    
    func releasePlayerThirst() {
        guard let scene = currentScene else { return }
        guard let player = player else { return }
        
        if player.hiddenAt != .none {
            gameEventsBus.addDangerMessage(message: "* Madness forces player get out from hideout *")
            movePlayerThroughHideouts(to: .none)
        }
        
        var npcs = scene.getNPCs()
            .filter( { $0.isAlive && !$0.isSpecialBehaviorSet })
        
        var randomVictim = npcs.randomElement()
        
        var amountOfBloodToFeed = 100 - player.bloodMeter.currentBlood
        
        if let randomVictim = randomVictim {
            gameEventsBus.addDangerMessage(message: "* Relentless blood thirst!*")
            try? FeedingService.shared.feedOnCharacter(vampire: player, prey: randomVictim, amount: amountOfBloodToFeed, in: scene.id)
            
            VibrationService.shared.errorVibration()
        }
    }
    
    private func endGame() {
        self.showEndGame = true
    }
    
    var isNightTime: Bool {
        return gameTime.isNightTime
    }
}
