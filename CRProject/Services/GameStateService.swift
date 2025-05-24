import Foundation
import UIKit
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
        player?.hiddenAt = to
        
        if player?.hiddenAt != nil {
            npcManager.selectedNPC = nil
        }
    }
    
    func movePlayerToNearestHideout() {
        guard let player = player else { return }
        guard let firstAvailableHideout = currentScene?.sceneType.possibleHidingCells().shuffled().first else { return }
        
        player.hiddenAt = firstAvailableHideout
    }
    
    func couldLeaveHideout() -> Bool {
        guard let player = player else { return false }
        guard let scene = currentScene else { return false }
        return (AbilitiesSystem.shared.hasDayWalker && player.bloodMeter.currentBlood > 80.0) || gameTime.isNightTime || scene.isIndoor
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
                VampireGazeSystem.shared.attemptGazePower(power: .follow, on: victim)
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
        player?.bloodMeter.useBlood(AbilitiesSystem.shared.hasLordOfBlood ? 1 : 2)
        
        // Reset selection if npc left location
        guard let scene = currentScene else { return }
        
        
        if !scene.isIndoor && !gameTime.isNightTime && (!AbilitiesSystem.shared.hasDayWalker || (AbilitiesSystem.shared.hasDayWalker &&  (player?.bloodMeter.currentBlood)! <= 70.0)) {
            endGame()
        }
        
        if npcManager.selectedNPC != nil {
            if !scene.hasCharacter(with: npcManager.selectedNPC!.id) {
                npcManager.selectedNPC = nil
            }
        }
        
        if isNeedToHide() {
            forcePlayerToFindHideout()
        }
        
        if AbilitiesSystem.shared.hasInsight {
            let unknownNpcs = scene.getNPCs().filter { $0.isUnknown }
            for npc in unknownNpcs {
                InvestigationService.shared.investigate(inspector: player!, investigationObject: npc)
            }
        }
        
        guard let player = player else { return }
        if player.isArrested {
            if player.arrestTime > 0 {
                player.arrestTime -= 1
            } else {
                player.isArrested = false
                player.arrestTime = 0
            }
        }

        // Update quest indicators for NPCs in the current scene
        let questService = QuestService.shared
        for npc in scene.getNPCs() { // Assuming scene.getNPCs() returns an array of NPC objects
            // Предполагаем, что свойства в NPC теперь Bool
            npc.hasNewQuests = questService.hasAvailableNewQuests(for: npc.id)
            npc.questStageUpdateAvaiting = questService.isNPCAwaitingPlayerActionInActiveQuests(for: npc.id)
            npc.isImportantNpc = questService.isImportantNpc(npcId: npc.id)
            // Если свойства Int, то:
            // npc.hasNewQuests = questService.hasAvailableNewQuests(for: npc.id) ? 1 : 0
            // npc.questStageUpdateAvaiting = questService.isNPCAwaitingPlayerActionInActiveQuests(for: npc.id) ? 1 : 0
        }
    }
    
    func forcePlayerToFindHideout() {
        guard let scene = currentScene else { return }
        guard let player = player else { return }
        
        if player.hiddenAt == HidingCell.none {
            player.hiddenAt = scene.sceneType.possibleHidingCells().randomElement() ?? .none
            
            gameEventsBus.addWarningMessage("You fleed from sun to nearby hiding spot")
            UIKitPopUpManager.shared.show(title: "Dawn", description: "Sun rises. You fleed to nearby spot", icon: UIImage(systemName: "sun.max.fill"))
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

        let currentPlayerBlood = player.bloodMeter.currentBlood
        
        if currentPlayerBlood <= 30 {
            gameEventsBus.addWarningMessage("* I feel huge lack of blood! *")
        }
        
        if currentPlayerBlood <= 10 {
            releasePlayerThirst()
        }
    }
    
    func releasePlayerThirst() {
        guard let scene = currentScene else { return }
        guard let player = player else { return }
        
        if player.hiddenAt != .none {
            gameEventsBus.addWarningMessage("* Thirst madness forces me get out from hideout! *")
            UIKitPopUpManager.shared.show(title: "Starved", description: "Your blood thirst became uncontrollable. Hight risk to drain anyone nearby", icon: UIImage(systemName: "drop"))
            return
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
            gameEventsBus.addWarningMessage("* Thirst madness forces me get out from hideout! *")
            UIKitPopUpManager.shared.show(title: "Blood madness", description: "Beast inside you took control over you. You just drained \(randomVictim.name) empty!", icon: UIImage(systemName: "drop.fill"))
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
    
    /// Проверяет, может ли игрок спрятаться на текущей сцене
    func checkCouldHide() -> Bool {
        guard let scene = currentScene else { return false }
        let npcs = scene.getNPCs()
        if npcs.isEmpty { return true }
        let awakeNpcs = npcs.filter { $0.currentActivity != .sleep && $0.isAlive }
        if awakeNpcs.isEmpty { return true }
        // Если есть бодрствующие, все ли они не под чарами (isSpecialBehaviorSet == false)?
        let allAwakeAreNotSpecial = awakeNpcs.allSatisfy { $0.isSpecialBehaviorSet == true }
        return allAwakeAreNotSpecial
    }
    
    func isNeedToHide() -> Bool {
        guard let scene = currentScene else { return false }
        guard let player = player else { return false }
        
        if scene.isIndoor || gameTime.isNightTime {
            return false
        } else {
            if AbilitiesSystem.shared.hasDayWalker && player.bloodMeter.currentBlood > 70.0 {
                return false
            } else {
                return player.hiddenAt == .none
            }
        }
    }
    
    
    func getAwakeNpcsCount() -> Int {
        guard let scene = currentScene else { return 0 }
        
        let npcs = scene.getNPCs()
            .filter( { $0.isAlive && !$0.isSpecialBehaviorSet && $0.currentActivity != .allyingPlayer && $0.currentActivity != .seductedByPlayer && $0.currentActivity != .sleep })
        
        return npcs.count
    }
}
