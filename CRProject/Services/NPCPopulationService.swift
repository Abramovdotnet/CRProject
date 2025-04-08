import Foundation
import Combine

class NPCPopulationService: GameService {
    private let gameStateService: GameStateService
    private let gameEventsBus: GameEventsBusService
    private var locationEventsService: LocationEventsService = DependencyManager.shared.resolve()
    private var npcManager = NPCInteractionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var eventsData: EventsData?
    
    // MARK: - Constants
    private let minAge: Int = 18
    private let maxAge: Int = 300
    private let minPopulation: Int = 1
    private let maxPopulation: Int = 30
    private let vampirePercentage: Float = 0.05// 5% of population should be vampires
    
    // Tracking state
    private var lastSceneId: UUID?
    
    // Scene-specific profession priorities
    private let sceneProfessionPriorities: [SceneType: [Profession]] = [
        .tavern: [.innkeeper, .wenche, .merchant],
        .inn: [.innkeeper, .wenche, .merchant],
        .temple: [.priest, .scribe],
        .shrine: [.priest, .scribe],
        .monastery: [.priest, .scribe],
        .greatCathedral: [.priest, .scribe],
        .garrison: [.guardman, .general],
        .guard_post: [.guardman, .general],
        .market: [.merchant, .baker, .butcher],
        .blacksmith: [.blacksmith, .armorer],
        .forge: [.blacksmith, .armorer],
        .alchemistShop: [.alchemist, .apothecary],
        .library: [.scribe, .herald],
        .archive: [.scribe, .herald],
        .farm: [.miller, .baker],
        .mill: [.miller, .baker],
        .guild: [.adventurer, .merchant],
        .mages_guild: [.alchemist, .scribe],
        .thieves_guild: [.adventurer, .merchant],
        .fighters_guild: [.guardman, .general],
        .district: [.merchant, .guardman, .adventurer, .priest, .innkeeper],
        .residential: [.merchant, .priest, .scribe],
        .house: [.merchant, .priest, .scribe],
        .estate: [.merchant, .priest, .scribe]
    ]
    
    init(gameStateService: GameStateService = DependencyManager.shared.resolve(),
         gameEventsBus: GameEventsBusService = DependencyManager.shared.resolve()) {
        self.gameStateService = gameStateService
        self.gameEventsBus = gameEventsBus
        loadGeneralEvents()
        DebugLogService.shared.log("NPCPopulationService initialized", category: "NPC")
    }
    
    private func loadGeneralEvents() {
        eventsData = EventsData.load()
        if eventsData == nil {
            DebugLogService.shared.log("Failed to load general events", category: "Error")
        }
    }
    
    private func getRelevantEvents(for scene: Scene, time: String) -> [EventTemplate] {
        guard let eventsData = eventsData else { return [] }
        
        return eventsData.events.filter { event in
            event.time == time &&
            event.sceneType == scene.sceneType.rawValue &&
            event.npcChangeRequired
        }
    }
    
    func updatePopulation(for scene: Scene) {
        let isNewScene = lastSceneId != scene.id
        
        DebugLogService.shared.log("Updating population for scene: \(scene.name) (\(scene.sceneType))", category: "NPC")
        
        // Store old population for comparison
        let oldPopulation = scene.getCharacters()
        
        let priorities = sceneProfessionPriorities[scene.sceneType] ?? []
        let availableNPCs = NPCReader.getNPCs()
        
        var adjustedPopulation = adjustPopulationForScene(
            oldPopulation,
            sceneType: scene.sceneType,
            priorities: priorities,
            availableNPCs: availableNPCs
        )

        scene.setCharacters(adjustedPopulation)
        
        // Compare populations and generate movement events
        let newPopulation = scene.getCharacters()
        handlePopulationChanges(isNewScene: isNewScene, oldPopulation: oldPopulation, newPopulation: newPopulation, scene: scene)
        
        // Reset selected npc reference, if exists
        if let selectedIndex = npcManager.selectedNPC?.index,
           !adjustedPopulation.contains(where: { $0.index == selectedIndex }) {
            npcManager.selectedNPC = nil
        }
        
        // Update tracking state
        lastSceneId = scene.id
        
        DebugLogService.shared.log("Population updated for scene: \(scene.name). Current count: \(newPopulation.count)", category: "NPC")
        
        // Check for location events
        /*let event = locationEventsService.generateEvent(scene: scene, isNight: gameStateService.isNightTime)
        
        if let event = event {
            locationEventsService.broadcastEvent(event)
        }*/
    }
    
    private func handlePopulationChanges(isNewScene: Bool, oldPopulation: [any Character], newPopulation: [any Character], scene: Scene) {
        let oldNPCs = Set(oldPopulation.compactMap { $0 as? NPC }.map { $0.id })
        let newNPCs = Set(newPopulation.compactMap { $0 as? NPC }.map { $0.id })
        
        if !isNewScene {
            // Find NPCs who left
            let leftNPCs = oldNPCs.subtracting(newNPCs)
            for npcId in leftNPCs {
                if let npc = oldPopulation.first(where: { ($0 as? NPC)?.id == npcId }) as? NPC {
                    
                    if !npc.isUnknown {
                        let eventText = generateProfessionDeparture(npc: npc, scene: scene)
                        let icon = "←🚶‍♂️ " // Walk-out icon
                        gameEventsBus.addCommonMessage(message: "\(icon)\(eventText)")
                    }
                }
            }
            
            // Find NPCs who arrived
            let arrivedNPCs = newNPCs.subtracting(oldNPCs)
            for npcId in arrivedNPCs {
                if let npc = newPopulation.first(where: { ($0 as? NPC)?.id == npcId }) as? NPC {
                    
                    if !npc.isUnknown {
                        let eventText = generateProfessionArrival(npc: npc, scene: scene)
                        let icon = "🚶‍♂️→ " // Walk-in icon
                        gameEventsBus.addCommonMessage(message: "\(icon)\(eventText)")
                    }
                }
            }
        }
    }
    
    private func generateProfessionArrival(npc: NPC, scene: Scene) -> String {
        switch npc.profession {
            case .merchant:
                return "\(npc.name) arrives at \(scene.name) to set up their trade."
            case .guardman:
                return "\(npc.name) begins their patrol duty in \(scene.name)."
            case .priest:
                return "\(npc.name) enters \(scene.name) to attend to their duties."
            case .innkeeper, .wenche:
                return "\(npc.name) arrives to work at \(scene.name)."
            default:
                return "\(npc.name) has entered \(scene.name)."
        }
    }
    
    private func generateProfessionDeparture(npc: NPC, scene: Scene) -> String {
        switch npc.profession {
            case .merchant:
                return "\(npc.name) packs up their goods and leaves \(scene.name)."
            case .guardman:
                return "\(npc.name) concludes their patrol in \(scene.name)."
            case .priest:
                return "\(npc.name) departs from \(scene.name) after their duties."
            case .innkeeper, .wenche:
                return "\(npc.name) finishes their shift at \(scene.name)."
            default:
                return "\(npc.name) has left \(scene.name)."
        }
    }
    
    private func adjustPopulationForScene(_ currentPopulation: [any Character], sceneType: SceneType, priorities: [Profession], availableNPCs: [NPC]) -> [any Character] {
        var newPopulation = currentPopulation
        let isNightTime = gameStateService.isNightTime
        
        // 1. Natural departure chance (some NPCs might leave)
        newPopulation = newPopulation.filter { character in
            guard let npc = character as? NPC else { return true }
            guard !npc.isBeasy else { return true }
            
            // Dead NPCs never leave (automatically kept)
            guard npc.isAlive else { return true }
            
            // NPCs are more likely to leave at night
            let baseLeaveChance = isNightTime ? 2.0 : 6.0
            // Priority NPCs are less likely to leave their posts
            let priorityMultiplier = priorities.contains(npc.profession) ? 0.53 : 1.0
            let finalLeaveChance = baseLeaveChance * priorityMultiplier
            
            var goingToleft = Double.random(in: 0...100) > finalLeaveChance
            
            if goingToleft {
                print("Left \(npc.name) in IsBeasy: \(npc.isBeasy)")
            }
            
            return goingToleft
        }
        
        // 2. Calculate how many new NPCs we can add
        let currentCount = newPopulation.count
        let targetCount =  Int(Float(getTargetPopulationCount(for: sceneType)))
        let spaceForNew = targetCount - currentCount
        
        // 3. Add new NPCs that match the scene type
        if spaceForNew > 0 {
            let appropriateNPCs = availableNPCs.filter { npc in
                isNPCAppropriateForScene(npc, sceneType: sceneType, priorities: priorities)
            }
            
            // Prioritize NPCs with matching professions
            let priorityNPCs = appropriateNPCs.filter { priorities.contains($0.profession) }
            let otherNPCs = appropriateNPCs.filter { !priorities.contains($0.profession) }
            
            // Add priority NPCs first, then others
            var newNPCs: [NPC] = []
            newNPCs += Array(priorityNPCs.prefix(max(1, spaceForNew)))
            newNPCs += Array(otherNPCs.prefix(spaceForNew - newNPCs.count))
            
            var arrivalChanceMultiplier = isNightTime ? 0.5 : 1.0
            // Adjust arrivalChange for fresh location
            if currentCount == 0 {
                arrivalChanceMultiplier *= 1.5
            }
            
            // Randomly decide which new NPCs actually enter (simulating natural flow)
            newNPCs = newNPCs.filter { _ in
                let arrivalChance = arrivalChanceMultiplier
                return Double.random(in: 0...1) < arrivalChance
            }
            
            newPopulation += newNPCs
        }
        
        for npc in newPopulation {
            npc.isBeasy = false
        }
        
        return newPopulation
    }
    
    private func isNPCAppropriateForScene(_ npc: NPC, sceneType: SceneType, priorities: [Profession]) -> Bool {
        // Priority professions are always appropriate
        if priorities.contains(npc.profession) {
            return true
        }
        
        // Night time restrictions
        if gameStateService.isNightTime {
            // Only certain professions are likely to be out at night
            let nightProfessions: Set<Profession> = [.guardman, .innkeeper, .wenche, .adventurer]
            if !nightProfessions.contains(npc.profession) {
                return Double.random(in: 0...1) > 0.8 // Small chance for others to be out at night
            }
        }
        
        // General appropriateness based on scene type
        switch sceneType {
        case .tavern, .inn:
            return true // Most people might visit taverns/inns
        case .temple, .shrine, .monastery, .greatCathedral:
            return Double.random(in: 0...1) > 0.5 // 50% chance for non-priority NPCs
        case .market, .district:
            return true // Most people visit markets and districts
        case .garrison, .guard_post:
            return npc.profession == .guardman || npc.profession == .general
        case .residential, .house, .estate:
            return Double.random(in: 0...1) > 0.7 // 30% chance for visitors
        default:
            return Double.random(in: 0...1) > 0.5 // 50% chance for other locations
        }
    }
    
    private func getTargetPopulationCount(for sceneType: SceneType) -> Int {
        switch sceneType {
        case .tavern, .inn, .district:
            return Int.random(in: 5...10)
        case .temple, .market, .shrine, .monastery, .greatCathedral, .garrison, .guard_post, .blacksmith, .forge, .alchemistShop, .library, .archive:
            return Int.random(in: 2...15)
        case .farm, .mill:
            return Int.random(in: 1...3)
        case .guild, .mages_guild, .thieves_guild, .fighters_guild:
            return Int.random(in: 3...7)
        case .residential, .house, .estate:
            return Int.random(in: 1...4)
        default:
            return Int.random(in: 2...10)
        }
    }
    
    private func getProfessionPriority(for sceneType: SceneType) -> [Profession] {
        switch sceneType {
        case .tavern, .inn:
            return [.innkeeper, .minstrel, .merchant, .adventurer]
        case .market:
            return [.merchant, .general, .miller]
        case .temple, .shrine, .monastery, .greatCathedral:
            return [.priest, .scribe]
        case .garrison, .guard_post:
            return [.guardman, .general]
        case .blacksmith, .forge:
            return [.blacksmith]
        case .alchemistShop:
            return [.alchemist]
        case .library, .archive:
            return [.scribe]
        case .farm, .mill:
            return [.miller]
        case .guild:
            return [.merchant, .general]
        case .mages_guild:
            return [.alchemist]
        case .thieves_guild:
            return [.general]
        case .fighters_guild:
            return [.adventurer, .general]
        case .residential, .house, .estate:
            return [.general, .merchant, .miller]
        case .district:
            return [.guardman, .merchant, .miller]
        default:
            return [.merchant, .adventurer]
        }
    }
    
    // MARK: - GameService Protocol
    
    func start() {
        DebugLogService.shared.log("NPCPopulationService started", category: "NPC")
        // Subscribe to scene changes
        gameStateService.$currentScene
            .sink { [weak self] scene in
                guard let scene = scene else { return }
                self?.updatePopulation(for: scene)
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        DebugLogService.shared.log("NPCPopulationService stopped", category: "NPC")
        cancellables.removeAll()
    }
} 
