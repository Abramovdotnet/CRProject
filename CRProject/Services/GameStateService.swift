import Foundation
import SwiftUICore
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

        // Subscribe to day/night changes
        NotificationCenter.default
            .publisher(for: .nightAppears)
            .sink { [weak self] _ in
                self?.handleNightAppears()
            }
            .store(in: &cancellables)
        
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
        
        CoinsManagementService.shared.updateWorldEconomy()
        ItemsManagementService.shared.distributeDailyItems()
    }
    
    func setPlayer(_ player: Player) {
        self.player = player
    }
    
    func getPlayer() -> Player? {
        return player
    }
    
    func movePlayerThroughHideouts(to: HidingCell) {
        let locationChange =  player?.hiddenAt == to
        player?.hiddenAt = to
        
        if player?.hiddenAt != nil {
            npcManager.selectedNPC = nil
        }
             
        if !locationChange {
            // Only increase awareness if player doesn't have the Ghost ability
            if !AbilitiesSystem.shared.hasGhost {
                // Get active NPCs
                guard let npcs = currentScene?.getNPCs().filter( { $0.currentActivity != .sleep && $0.currentActivity != .bathe && $0.currentActivity != .fleeing && $0.isSpecialBehaviorSet == false }) else { return }
                
                let npcCount = npcs.count
                
                if npcCount > 0 {
                    let awarenessIncrease = 4 * npcCount
                    vampireNatureRevealService.increaseAwareness(amount: Float(awarenessIncrease))
                    gameEventsBus.addWarningMessage("* \(npcCount) characters just saw by strange \(to == .none ? "appearance" : "disappearance")! *")
                }
            }
            
            // Track disappearances for Ghost ability
            if to != .none {
                StatisticsService.shared.increaseDisappearances()
            }
        }
    }
    
    func whisperToRandomNpc() {
        if player?.hiddenAt != HidingCell.none {
            guard let npcs = currentScene?.getNPCs().filter( { $0.currentActivity != .sleep && $0.currentActivity != .bathe && $0.currentActivity != .fleeing && $0.isSpecialBehaviorSet == false }) else { return }
            
            if npcs.count > 0 {
                let victim = npcs.randomElement()!
                
                if victim.isUnknown {
                    InvestigationService.shared.investigate(inspector: player!, investigationObject: victim)
                }
                
                npcManager.selectedNPC = victim
                VampireGaze.shared.attemptGazePower(power: .follow, on: victim)
                gameEventsBus.addWarningMessage("* \(victim.isUnknown ? "stranger" : victim.name) heard your whisper and obeyed. *")
            } else {
                gameEventsBus.addWarningMessage("* My whisper left no echo.*")
            }
        }
    }
    
    func changeLocation(to locationId: Int) throws {
        DebugLogService.shared.log("Changing location to ID: \(locationId)", category: "Location")
        
        movePlayerThroughHideouts(to: .none)
        
        // Try to find and set the new location
        let newLocation = try LocationReader.getRuntimeLocation(by: locationId)
        DebugLogService.shared.log("Found new location: \(newLocation.name)", category: "Location")
        
        if !newLocation.isLocked {
            // Update current scene
            currentScene = newLocation
            DebugLogService.shared.log("Current scene set to: \(currentScene?.name ?? "None")", category: "Location")
            
            // Update related locations
            updateRelatedLocations(for: locationId)
            
            npcManager.selectedNPC = nil
            
            // Advance time when changing location
            gameTime.advanceTime()
        } else {
            DebugLogService.shared.log("Cannot travel to locked location", category: "Location")
            gameEventsBus.addDangerMessage(message: "*I cannot move to this location*")
        }
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
        NPCBehaviorService.shared.updateNPCsActivities()
        advanceWorldState()
        
        // Reduce player blood pool
        player?.bloodMeter.useBlood(AbilitiesSystem.shared.hasLordOfBlood ? 2 : 4)
        
        // Reset selection if npc left location
        guard let scene = currentScene else { return }
        
        if npcManager.selectedNPC != nil {
            if !scene.hasCharacter(with: npcManager.selectedNPC!.id) {
                npcManager.selectedNPC = nil
            }
        }
        
        if !scene.isIndoor && !gameTime.isNightTime {
            if !AbilitiesSystem.shared.hasDayWalker && (player?.bloodMeter.currentBlood)! >= 70.0 {
                forcePlayerToFindHideout()
            }
        }
    }
    
    func forcePlayerToFindHideout() {
        guard let scene = currentScene else { return }
        guard let player = player else { return }
        
        if player.hiddenAt == HidingCell.none {
            player.hiddenAt = scene.sceneType.possibleHidingCells().randomElement() ?? .none
            
            gameEventsBus.addWarningMessage("* My blood boiling under direct sunlight!*" )
        }
    }
    
    func handleNightAppears() {
        player?.desiredVictim.updateDesiredVictim()
        

        CoinsManagementService.shared.updateWorldEconomy()
        ItemsManagementService.shared.distributeDailyItems()
    }
    
    private func handleSafeTimeAdvanced() {
        NPCBehaviorService.shared.updateNPCsActivities()
        advanceWorldState(advanceSafe: true)
        
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
        
        let activeNpcs = scene.getNPCs()
            .filter( { $0.isAlive && !$0.isSpecialBehaviorSet && $0.currentActivity != .sleep})
        
        if player.hiddenAt == .none && activeNpcs.count > 0 {
            vampireNatureRevealService.increaseAwareness(amount: 1)
        }

        let currentPlayerBlood = player.bloodMeter.currentBlood
        
        if currentPlayerBlood <= 30 {
            gameEventsBus.addWarningMessage("* I feel huge lack of blood! *")
            PopUpState.shared.show(title: "Uncontrollable blood lust", details: "If blood pool goes under 10%, you will loose control over your actions and drain empty random victim.", image: .system(name: "drop.fill", color: .red))
        }
        
        if currentPlayerBlood <= 10 {
            releasePlayerThirst()
        }
    }
    
    func releasePlayerThirst() {
        guard let scene = currentScene else { return }
        guard let player = player else { return }
        
        if !scene.isIndoor && !gameTime.isNightTime {
            endGame()
        }
        
        if player.hiddenAt != .none {
            gameEventsBus.addWarningMessage("* Thirst madness forces me get out from hideout! *")
            movePlayerThroughHideouts(to: .none)
        }
        
        if player.onCraftingProcess {
            player.onCraftingProcess = false
            gameEventsBus.addWarningMessage("* Can't continue work under uncontrollable thirst! *")
            movePlayerThroughHideouts(to: .none)
        }
        
        let npcs = scene.getNPCs()
            .filter( { $0.isAlive && !$0.isSpecialBehaviorSet })
        
        let randomVictim = npcs.randomElement()

        if let randomVictim = randomVictim {
            gameEventsBus.addWarningMessage("* Relentless blood thirst! *")
            try? FeedingService.shared.emptyBlood(vampire: player, prey: randomVictim, in: scene.id)
            
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
