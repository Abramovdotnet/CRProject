import Foundation

class LocationEventsService : GameService {
    private var events: [EventTemplate] = []
    private weak var gameEventsBus: GameEventsBusService?
    private weak var vampireNatureRevealService: VampireNatureRevealService?
    private weak var gameStateService: GameStateService?
    private var lastNPCs: [UUID: any Character] = [:]
    private var deadNPCs: [UUID: any Character] = [:]  // Track dead NPCs
    
    init(gameEventsBus: GameEventsBusService, vampireNatureRevealService: VampireNatureRevealService, gameStateService: GameStateService) {
        self.gameEventsBus = gameEventsBus
        self.vampireNatureRevealService = vampireNatureRevealService
        self.gameStateService = gameStateService
        loadEvents()
    }
    
    private func loadEvents() {
        do {
            // First try to load from main bundle
            if let url = Bundle.main.url(forResource: "GeneralEvents", withExtension: "json") {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let json = try decoder.decode(EventsData.self, from: data)
                events = json.events
                return
            }
            
            // If not found in main bundle, try to load from the Resources directory
            let fileManager = FileManager.default
            let currentDirectory = fileManager.currentDirectoryPath
            let resourcesPath = (currentDirectory as NSString).appendingPathComponent("CRProject/Resources/GeneralEvents.json")
            
            if fileManager.fileExists(atPath: resourcesPath) {
                let data = try Data(contentsOf: URL(fileURLWithPath: resourcesPath))
                let decoder = JSONDecoder()
                let json = try decoder.decode(EventsData.self, from: data)
                events = json.events
                return
            }
            
            // If still not found, try to load from the project directory
            let projectPath = (currentDirectory as NSString).appendingPathComponent("GeneralEvents.json")
            if fileManager.fileExists(atPath: projectPath) {
                let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
                let decoder = JSONDecoder()
                let json = try decoder.decode(EventsData.self, from: data)
                events = json.events
                return
            }
            
            DebugLogService.shared.log("Could not find GeneralEvents.json in any location", category: "Error")
        } catch {
            DebugLogService.shared.log("Error loading events: \(error.localizedDescription)", category: "Error")
            DebugLogService.shared.log("Error details: \(error)", category: "Error")
        }
    }
    
    private func hasNPCsChanged(scene: Scene) -> Bool {
        let currentNPCs = scene.getCharacters().reduce(into: [UUID: any Character]()) { $0[$1.id] = $1 }
        
        // Check for newly dead NPCs
        for (id, npc) in lastNPCs {
            if let currentNPC = currentNPCs[id], !currentNPC.isAlive && npc.isAlive {
                deadNPCs[id] = npc
                DebugLogService.shared.log("NPC \(npc.name) has died!", category: "Event")
                // Increase awareness when an NPC dies
                vampireNatureRevealService?.increaseAwareness(for: scene.id, amount: 30)
            }
        }
        
        let hasChanged = !currentNPCs.keys.elementsEqual(lastNPCs.keys)
        lastNPCs = currentNPCs
        return hasChanged || !deadNPCs.isEmpty
    }
    
    private func hasVampire(scene: Scene) -> Bool {
        return scene.getCharacters().contains { $0.isVampire }
    }
    
    private func getLocationType(scene: Scene) -> String {
        // This is a simplified version. You should implement proper location type detection
        if scene.name.lowercased().contains("tavern") {
            return "tavern"
        } else if scene.name.lowercased().contains("castle") {
            return "castle"
        } else if scene.name.lowercased().contains("market") {
            return "market"
        } else if scene.name.lowercased().contains("blacksmith") {
            return "blacksmith"
        } else {
            return "street"
        }
    }
    
    private func getMatchingEvents(scene: Scene, isNight: Bool) -> [EventTemplate] {
        let awarenessLevel = vampireNatureRevealService?.getAwareness(for: scene.id) ?? 0
        
        // If there are dead NPCs, prioritize death-related events
        if !deadNPCs.isEmpty {
            return events.filter { event in
                // Basic conditions
                guard event.time == (isNight ? "night" : "day") &&
                        event.locationType == scene.sceneType.rawValue &&
                        event.sceneType == scene.sceneType.rawValue &&
                      event.isIndoors == scene.isIndoor else {
                    return false
                }
                
                // NPC count check
                let npcCount = scene.getCharacters().count
                guard npcCount >= event.minNPCs && npcCount <= event.maxNPCs else {
                    return false
                }
                
                // Awareness level check - prioritize high awareness for death events
                guard Int(awarenessLevel) >= event.minAwareness && Int(awarenessLevel) <= event.maxAwareness else {
                    return false
                }
                
                // Check for required professions
                if !event.requiredProfessions.isEmpty {
                    let hasRequiredProfession = scene.getCharacters().contains { npc in
                        event.requiredProfessions.contains(npc.profession.rawValue)
                    }
                    guard hasRequiredProfession else {
                        return false
                    }
                }
                
                // Prioritize events that mention death, discovery, or investigation
                let deathRelatedKeywords = ["discovery", "panic", "hunt", "meeting", "funeral", "vigil", "warning"]
                return deathRelatedKeywords.contains { event.id.contains($0) }
            }
        }
        
        // Regular event filtering for non-death situations
        return events.filter { event in
            DebugLogService.shared.log("Checking event: \(event.id)", category: "Event")
            
            // Check time of day
            guard event.time == (isNight ? "night" : "day") else {
                DebugLogService.shared.log("Time mismatch: Event requires \(event.time), current time is \(isNight ? "night" : "day")", category: "Event")
                return false
            }
            
            // Check NPC count
            let npcCount = scene.getCharacters().count
            guard npcCount >= event.minNPCs && npcCount <= event.maxNPCs else {
                DebugLogService.shared.log("NPC count mismatch: Event requires \(event.minNPCs)-\(event.maxNPCs) NPCs, current count is \(npcCount)", category: "Event")
                return false
            }
            
            // Check required genders
            if !event.requiredGenders.isEmpty {
                let hasRequiredGender = scene.getCharacters().contains { npc in
                    event.requiredGenders.contains(npc.sex.rawValue)
                }
                guard hasRequiredGender else {
                    DebugLogService.shared.log("Missing required gender: \(event.requiredGenders)", category: "Event")
                    return false
                }
            }
            
            // Check required ages
            if !event.requiredAges.isEmpty {
                let hasRequiredAge = scene.getCharacters().contains { npc in
                    npc.age >= event.requiredAges[0] && npc.age <= event.requiredAges[1]
                }
                guard hasRequiredAge else {
                    DebugLogService.shared.log("Missing required age range: \(event.requiredAges)", category: "Event")
                    return false
                }
            }
            
            // Check blood level
            let bloodLevel = gameStateService?.getPlayer()?.bloodMeter.currentBlood ?? 0
            guard Int(bloodLevel) >= event.minBloodLevel && Int(bloodLevel) <= event.maxBloodLevel else {
                DebugLogService.shared.log("Blood level mismatch: Event requires \(event.minBloodLevel)-\(event.maxBloodLevel), current level is \(bloodLevel)", category: "Event")
                return false
            }
            
            // Check sleeping state
            if event.sleepingRequired {
                let hasSleepingNPC = scene.getCharacters().contains { $0.isSleeping }
                guard hasSleepingNPC else {
                    DebugLogService.shared.log("Missing sleeping NPC", category: "Event")
                    return false
                }
            }
            
            // Check indoor/outdoor
            guard event.isIndoors == scene.isIndoor else {
                DebugLogService.shared.log("Indoor/outdoor mismatch: Event requires \(event.isIndoors ? "indoors" : "outdoors")", category: "Event")
                return false
            }
            
            // Check location type
            let currentLocationType = getLocationType(scene: scene)
            guard event.locationType == currentLocationType else {
                DebugLogService.shared.log("Location type mismatch: Event requires \(event.locationType), current type is \(currentLocationType)", category: "Event")
                return false
            }
            
            // Check scene type
            guard event.sceneType == scene.sceneType.rawValue else {
                DebugLogService.shared.log("Scene type mismatch: Event requires \(event.sceneType), current type is \(scene.sceneType.rawValue)", category: "Event")
                return false
            }
            
            // Check NPC change requirement
            if event.npcChangeRequired {
                guard hasNPCsChanged(scene: scene) else {
                    DebugLogService.shared.log("NPCs haven't changed", category: "Event")
                    return false
                }
            }
            
            // Check vampire presence
            let hasVampire = hasVampire(scene: scene)
            switch event.vampirePresence {
            case "required":
                guard hasVampire else {
                    DebugLogService.shared.log("Missing required vampire", category: "Event")
                    return false
                }
            case "forbidden":
                guard !hasVampire else {
                    DebugLogService.shared.log("Vampire present when forbidden", category: "Event")
                    return false
                }
            case "optional":
                break
            default:
                break
            }
            
            DebugLogService.shared.log("Event \(event.id) passed all checks", category: "Event")
            return true
        }
    }
    
    func generateEvent(scene: Scene, isNight: Bool) -> String? {
        let hasChanged = hasNPCsChanged(scene: scene)
        let matchingEvents = getMatchingEvents(scene: scene, isNight: isNight)
        
        guard !matchingEvents.isEmpty else {
            DebugLogService.shared.log("No matching events found", category: "Event")
            return nil
        }
        
        let selectedEvent = matchingEvents.randomElement()!
        let npcs = scene.getCharacters().shuffled()
        
        var eventText = selectedEvent.template
        
        // Replace NPC placeholders with actual names
        for i in 1...3 {
            if i <= npcs.count {
                eventText = eventText.replacingOccurrences(of: "{NPC\(i)}", with: npcs[i-1].name)
            }
        }
        
        // Clear dead NPCs list after generating a death-related event
        if selectedEvent.id.contains("discovery") || selectedEvent.id.contains("funeral") {
            deadNPCs.removeAll()
        }
        
        return eventText
    }
    
    func broadcastEvent(_ eventText: String) {
        DispatchQueue.main.async { [weak self] in
            self?.gameEventsBus?.addEventMessage(eventText)
        }
    }
}
