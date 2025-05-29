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
        guard let scene = currentScene else { return }
        player?.hiddenAt = to
        
        if player?.hiddenAt != nil {
            npcManager.selectedNPC = nil
            
            if isAmbushAvailable() {
                let mobs = scene.getNPCs().filter( { $0.isAlive && $0.isMob })
                
                if mobs.count > 0 {
                    guard let firstMob = mobs.first else { return }
                    
                    UIKitPopUpManager.shared.show(
                        title: "Encounter",
                        description: "\(firstMob.name) charges into you!",
                        icon: UIImage(systemName: NPCActivityType.combat.icon)
                    )
                    startCombat(npc: firstMob)
                }
            }
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
            guard let npcs = currentScene?.getNPCs().filter( { !$0.isMob && $0.currentActivity != .sleep && $0.currentActivity != .bathe && $0.currentActivity != .fleeing && $0.isSpecialBehaviorSet == false }) else { return }
            
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
        guard let player = player else { return }
        DebugLogService.shared.log("Changing location to ID: \(locationId)", category: "Location")
        
        movePlayerThroughHideouts(to: .none)
        
        // Try to find and set the new location
        let newLocation = try LocationReader.getRuntimeLocation(by: locationId)
        DebugLogService.shared.log("Found new location: \(newLocation.name)", category: "Location")
        
        if !newLocation.isLocked {
            removeMobsIfNeeded()
            // Update current scene
            currentScene = newLocation
            DebugLogService.shared.log("Current scene set to: \(currentScene?.name ?? "None")", category: "Location")
            
            // Update related locations
            updateRelatedLocations(for: locationId)
            
            npcManager.selectedNPC = nil
            
            player.currentLocationId = currentScene?.id ?? newLocation.id
            
            spawnMobsIfNeeded()
            
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
        guard let player = player else { return }

        NPCBehaviorService.shared.updateNPCsActivities()
        advanceWorldState()
        
        // Reduce player blood pool
        BloodManagementService.shared.reduceBloodIfNeeded(player: player)
        
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
                player.isWanted = false
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
            UIKitPopUpManager.shared.show(title: "Dawn", description: "Sun rises. You fled to nearby spot", icon: UIImage(systemName: "sun.max.fill"))
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
        
        let currentPlayerBlood = player.bloodMeter.currentBlood
        
        if currentPlayerBlood <= 30 {
            gameEventsBus.addWarningMessage("* I feel huge lack of blood! *")
        }
        
        if currentPlayerBlood <= 10 {
            releasePlayerThirst()
        }
        
        spawnMobsIfNeeded()
        if isAmbushAvailable() {
            let mobs = scene.getNPCs().filter( { $0.isAlive && $0.isMob })
            
            if mobs.count > 0 {
                guard let firstMob = mobs.first else { return }
                
                UIKitPopUpManager.shared.show(
                    title: "Ambush",
                    description: "You'we been ambushed by \(firstMob.name)!",
                    icon: UIImage(systemName: NPCActivityType.combat.icon)
                )
                startCombat(npc: firstMob)
            }
        } else {
            chasePlayerIfWanted()
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
    
    func endGame() {
        self.showEndGame = true
    }
    
    var isNightTime: Bool {
        return gameTime.isNightTime
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
        let npcs = getAwakeNpcs()
        return npcs.count
    }
    
    func getAwakeMobsCount() -> Int {
        let mobs = getAwakeMobs()
        return mobs.count
    }
    
    func getAwakeMobs() -> [NPC] {
        guard let scene = currentScene else { return [] }
        
        return scene.getNPCs().filter( {$0.isMob && $0.isAlive && !$0.isSpecialBehaviorSet })
    }
    
    func getAwakeNpcs() -> [NPC] {
        guard let scene = currentScene else { return [] }
        
        let npcs = scene.getNPCs()
            .filter( { !$0.isMob && $0.isAlive && !$0.isSpecialBehaviorSet && $0.currentActivity != .allyingPlayer && $0.currentActivity != .seductedByPlayer && $0.currentActivity != .sleep })
        
        return npcs
    }

    func getWitnessesCount() -> Int {
        let awakeNpcs = getAwakeNpcs()

        if awakeNpcs.count > 1 {
            return awakeNpcs.count - 1
        } else {
            return 0
        }
    }
    
    func getNPCAssistants(npc: NPC) -> [NPC] {
        guard let scene = currentScene else { return [] }
        npc.decreasePlayerRelationship(with: 10)
        
        var npcs = scene.getNPCs()
        
        if npc.isMob {
            npcs = npcs.filter { $0.isMob }
        } else {
            npcs = npcs.filter { !$0.isMob }
        }
        let aliveNpcs = npcs.filter( { $0.id != npc.id && $0.isAlive && !$0.isSpecialBehaviorSet})
        
        var allies: [NPC] = []
        
        let protectorNpcs = aliveNpcs.filter( { $0.morality == .lawfulGood || $0.morality == .neutralGood || $0.morality == .chaoticGood })
        allies.append(contentsOf: protectorNpcs)
        
        
        if !npc.isMob {
            // Добавляем всех военных NPC (стража)
            let militaryNpcs = aliveNpcs.filter( { $0.isMilitary })
            for militaryNpc in militaryNpcs {
                // Избегаем дубликатов
                if !allies.contains(where: { $0.id == militaryNpc.id }) {
                    allies.append(militaryNpc)
                }
            }
        } else {
            let mobs = aliveNpcs.filter({ $0.isMob && $0.mobType == npc.mobType })
            
            if mobs.count > 0 {
                for mob in mobs {
                    allies.append(mob)
                }
            }
        }
        
        // Добавляем всех NPC из aliveNpcs, которые связаны с текущим NPC отношениями >= friend
        for aliveNpc in aliveNpcs {
            // Проверяем отношение этого NPC к целевому NPC
            if let relationshipState = aliveNpc.getNPCRelationshipState(of: npc) {
                if relationshipState == .friend || relationshipState == .ally {
                    // Избегаем дубликатов
                    if !allies.contains(where: { $0.id == aliveNpc.id }) {
                        allies.append(aliveNpc)
                    }
                }
            }
            
            // Делаем NPC видимыми (убираем unknown статус)
            if aliveNpc.isUnknown {
                aliveNpc.isUnknown = false
            }
        }
        
        for ally in allies {
            ally.decreasePlayerRelationship(with: 10)
        }
        
        return allies
    }
    
    func callTheGuardsIfNeeded(engagedInFight: [NPC]) -> [NPC]? {
        // Проверка наличия мертвых NPC в бою
        guard engagedInFight.contains(where: { !$0.isAlive }) else { return nil }
        
        // Получаем первого свидетеля, не участвующего в бою
        guard let witness = getAwakeNpcs().first(where: { witness in
            !engagedInFight.contains { $0.id == witness.id }
        }) else { return nil }
        
        // Показываем уведомление о свидетеле
        UIKitPopUpManager.shared.show(
            title: "Public kill",
            description: "\(witness.name) saw the crime and called for guards",
            icon: UIImage(systemName: "shield")
        )
        
        player?.isWanted = true
        
        witness.currentActivity = .fleeing
        witness.isSpecialBehaviorSet = true
        witness.specialBehaviorTime = 3
        witness.decreasePlayerRelationship(with: 20)
        
        // Получаем доступных стражей
        let availableGuards = NPCReader.getNPCs()
            .filter { $0.isAlive && $0.isMilitary }
            .prefix(2)
        
        for availableGuard in availableGuards {
            if availableGuard.isUnknown {
                availableGuard.isUnknown = false
            }
            
            availableGuard.decreasePlayerRelationship(with: 20)
        }
        
        return availableGuards.isEmpty ? nil : Array(availableGuards)
    }
    
    func jailPlayer() {
        guard let player = GameStateService.shared.player else { return }
        guard let jailLocation = LocationReader.getLocations().first(where: { $0.sceneType == .dungeon }) else { return }
        try? GameStateService.shared.changeLocation(to: jailLocation.id)
        player.arrestPlayer()
        
        UIKitPopUpManager.shared.show(
            title: "Arrest",
            description: "You'we been jailed for \(StatisticsService.shared.timesArrested * 24) hours",
            icon: UIImage(systemName: NPCActivityType.jailed.icon)
        )
    }
    
    func isAmbushAvailable() -> Bool {
        guard !CombatService.shared.isCombatActive else { return false }
        guard let player = player else { return false }
        
        if player.hiddenAt == .none {
            guard let scene = currentScene else { return false }
            let npcs = scene.getNPCs().filter( { $0.isAlive && !$0.isSpecialBehaviorSet })
            return npcs.allSatisfy( { $0.isMob } )
        } else {
            return false
        }
    }
    
    func startCombat(npc: NPC) {
        CombatService.shared.isCombatActive = true
        DispatchQueue.main.async {
            // Устанавливаем выбранного NPC
            NPCInteractionManager.shared.selectedNPC = npc
            
            // Отправляем уведомление для открытия боевой сцены
            NotificationCenter.default.post(name: Notification.Name("startBattle"), object: npc)
        }
    }
    
    func endCombat() {
        CombatService.shared.isCombatActive = false
        gameTime.advanceTime()
        
        DispatchQueue.main.async {
            // Отправляем уведомление для возврата в главную сцену
            NotificationCenter.default.post(name: Notification.Name("returnToMainScene"), object: nil)
        }
    }
    
    // MARK: - Usage Example
    // Пример использования:
    // if let someNPC = scene.getNPCs().first {
    //     GameStateService.shared.startBattle(npc: someNPC)
    // }
    // Этот метод автоматически вернет игрока в главную сцену (если он не в ней)
    // и откроет боевую сцену с указанным NPC
    
    func chasePlayerIfWanted() {
        guard !CombatService.shared.isCombatActive else { return }
        guard let player = player else { return }
        
        if player.isWanted && player.hiddenAt == .none && !player.isArrested {
            let militaryNpcs = getAwakeNpcs().filter( { $0.isMilitary })
            
            if militaryNpcs.count > 0 {
                UIKitPopUpManager.shared.show(
                    title: "Chased",
                    description: "You'we been chased for your crimes by \(militaryNpcs.first!.name)!",
                    icon: UIImage(systemName: NPCActivityType.combat.icon)
                )
                startCombat(npc: militaryNpcs.first!)
            }
        }
    }
    
    func spawnMobsIfNeeded() {
        guard let scene = currentScene else { return }
        
        let sceneType = scene.sceneType
        var mobType = MobType.none
        
        if sceneType == .cave || sceneType == .forest || sceneType == .ruins {
            let humanWeight: Double = 0.75
            
            let isNeedToSpawnHuman = Double.random(in: 0...1) > humanWeight
            
            if isNeedToSpawnHuman {
                let assassinWeigth = 0.9
                
                let isNeedToSpawnAssassin = Double.random(in: 0...1) > assassinWeigth
                
                if isNeedToSpawnAssassin {
                    mobType = .assassin
                } else {
                    mobType = .bandit
                }
            } else {
                let weight = Double.random(in: 0...1)
                
                if weight > 0.9 {
                    mobType = .puma
                } else if weight > 0.7 {
                    mobType = .bear
                } else if weight > 0.5 {
                    mobType = .wildBoar
                } else {
                    mobType = .wolf
                }
            }

        } else if sceneType == .crypt || sceneType == .road || sceneType == .square || sceneType == .cemetery {
            let assassinWeigth = 0.9
            let marauderWeight = 0.7
            
            let npcWeight = Double.random(in: 0...1)
            let isNeedToSpawnAssassin = npcWeight >= assassinWeigth
            let isNeedToSpawnMarauder = npcWeight >= marauderWeight && npcWeight < assassinWeigth
            
            if isNeedToSpawnAssassin {
                mobType = .assassin
            } else if isNeedToSpawnMarauder  {
                mobType = .marauder
            } else {
                mobType = .bandit
            }
        }
        let wouldSpawn = Int.random(in: 1...10) > 9
        
        if wouldSpawn {
            let isDayPhaseMet = Double.random(in: 0...1) > (gameTime.isNightTime ? 0.3 : 0.8)
            
            if isDayPhaseMet && mobType != .none {
                return MobManager.shared.spawnMobAtScene(ofType: mobType, at: scene.id)
            }
        }
    }
    
    func removeMobsIfNeeded() {
        guard let scene = currentScene else { return }
        
        let mobs = scene.getNPCs().filter({ $0.isMob })
        
        for mob in mobs {
            scene.removeCharacter(id: mob.id)
        }
    }
}
