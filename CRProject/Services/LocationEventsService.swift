import Foundation

class LocationEventsService : GameService {
    private var events: [EventTemplate] = []
    private weak var gameEventsBus: GameEventsBusService?
    private weak var vampireNatureRevealService: VampireNatureRevealService?
    private weak var gameStateService: GameStateService?
    private var lastNPCs: [UUID: any Character] = [:]
    
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
    
    func updateNPCSleepingState(scene: Scene, isNight: Bool) {
        let sleepChance = isNight ? 90 : 10 // 90% chance at night, 10% during day
        
        for npc in scene.getCharacters() {
            if !npc.isVampire && npc.isAlive {
                let shouldSleep = Int.random(in: 0...100) < sleepChance
                npc.isSleeping = shouldSleep
                DebugLogService.shared.log("\(npc.name) is sleeping: \(shouldSleep)", category: "NPC")
            }
        }
    }
    
    private func hasNPCsChanged(scene: Scene) -> Bool {
        let currentNPCs = scene.getCharacters().reduce(into: [UUID: any Character]()) { $0[$1.id] = $1 }
        let hasChanged = !currentNPCs.keys.elementsEqual(lastNPCs.keys)
        lastNPCs = currentNPCs
        return hasChanged
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
    
    func generateEvent(scene: Scene, isNight: Bool) -> String? {
        DebugLogService.shared.log("=== Starting Event Generation ===", category: "Event")
        DebugLogService.shared.log("Scene: \(scene.name)", category: "Event")
        DebugLogService.shared.log("Is Night: \(isNight)", category: "Event")
        DebugLogService.shared.log("Total available events: \(events.count)", category: "Event")
        
        guard let vampireNatureRevealService = vampireNatureRevealService,
              let gameStateService = gameStateService else {
            DebugLogService.shared.log("Required services are nil", category: "Error")
            return nil
        }
        
        let availableEvents = events.filter { event in
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
            
            // Check required professions
            if !event.requiredProfessions.isEmpty {
                let hasRequiredProfession = scene.getCharacters().contains { npc in
                    event.requiredProfessions.contains(npc.profession.rawValue)
                }
                guard hasRequiredProfession else {
                    DebugLogService.shared.log("Missing required profession: \(event.requiredProfessions)", category: "Event")
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
            let bloodLevel = gameStateService.getPlayer()?.bloodMeter.currentBlood ?? 0
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
            
            // Check awareness level
            let awarenessLevel = vampireNatureRevealService.getAwareness(for: scene.id )
            guard Int(awarenessLevel) >= event.minAwareness && Int(awarenessLevel) <= event.maxAwareness else {
                DebugLogService.shared.log("Awareness level mismatch: Event requires \(event.minAwareness)-\(event.maxAwareness), current level is \(awarenessLevel)", category: "Event")
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
        
        DebugLogService.shared.log("Found \(availableEvents.count) matching events", category: "Event")
        
        guard let selectedEvent = availableEvents.randomElement() else {
            DebugLogService.shared.log("No matching events found", category: "Error")
            return nil
        }
        
        DebugLogService.shared.log("Selected event: \(selectedEvent.id)", category: "Event")
        DebugLogService.shared.log("Template: \(selectedEvent.template)", category: "Event")
        
        // Replace placeholders in the template
        var eventText = selectedEvent.template
        let characters = scene.getCharacters()
        
        // Replace NPC placeholders
        var usedNPCIds: Set<String> = []
        for i in 1... {
            let placeholder = "{NPC\(i)}"
            if eventText.contains(placeholder) {
                // Filter out already used NPCs
                let availableNPCs = characters.filter { !usedNPCIds.contains($0.id.uuidString) }
                if let randomNPC = availableNPCs.randomElement() {
                    eventText = eventText.replacingOccurrences(of: placeholder, with: randomNPC.name)
                    usedNPCIds.insert(randomNPC.id.uuidString)
                    DebugLogService.shared.log("Replaced \(placeholder) with \(randomNPC.name)", category: "Event")
                } else {
                    eventText = eventText.replacingOccurrences(of: placeholder, with: "someone")
                    DebugLogService.shared.log("Replaced \(placeholder) with 'someone'", category: "Event")
                }
            } else {
                break
            }
        }
        
        // Replace {LOCATION}
        eventText = eventText.replacingOccurrences(of: "{LOCATION}", with: scene.name)
        DebugLogService.shared.log("Replaced {LOCATION} with \(scene.name)", category: "Event")
        
        DebugLogService.shared.log("Final event text: \(eventText)", category: "Event")
        DebugLogService.shared.log("=== End Event Generation ===", category: "Event")
        
        return eventText
    }
    
    func broadcastEvent(_ eventText: String) {
        DispatchQueue.main.async { [weak self] in
            self?.gameEventsBus?.addEventMessage(eventText)
        }
    }
}
