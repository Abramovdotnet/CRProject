import Foundation

class LocationEventsService : GameService {
    private var events: [EventTemplate] = []
    private weak var gameEventsBus: GameEventsBusService?
    private weak var vampireNatureRevealService: VampireNatureRevealService?
    
    init(gameEventsBus: GameEventsBusService, vampireNatureRevealService: VampireNatureRevealService) {
        self.gameEventsBus = gameEventsBus
        self.vampireNatureRevealService = vampireNatureRevealService
        loadEvents()
    }
    
    private func loadEvents() {
        do {
            // First try to load from main bundle
            if let url = Bundle.main.url(forResource: "GeneralEvents", withExtension: "json") {
                let data = try Data(contentsOf: url)
                let json = try JSONDecoder().decode(EventsData.self, from: data)
                events = json.events
                return
            }
            
            // If not found in main bundle, try to load from the Resources directory
            let fileManager = FileManager.default
            let currentDirectory = fileManager.currentDirectoryPath
            let resourcesPath = (currentDirectory as NSString).appendingPathComponent("CRProject/Resources/GeneralEvents.json")
            
            if fileManager.fileExists(atPath: resourcesPath) {
                let data = try Data(contentsOf: URL(fileURLWithPath: resourcesPath))
                let json = try JSONDecoder().decode(EventsData.self, from: data)
                events = json.events
                return
            }
            
            // If still not found, try to load from the project directory
            let projectPath = (currentDirectory as NSString).appendingPathComponent("GeneralEvents.json")
            if fileManager.fileExists(atPath: projectPath) {
                let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
                let json = try JSONDecoder().decode(EventsData.self, from: data)
                events = json.events
                return
            }
            
            print("Error: Could not find GeneralEvents.json in any location")
        } catch {
            print("Error loading events: \(error.localizedDescription)")
            print("Error details: \(error)")
        }
    }
    
    func updateNPCSleepingState(scene: Scene, isNight: Bool) {
        let sleepChance = isNight ? 0.8 : 0.1 // 80% chance at night, 10% during day
        
        for npc in scene.getCharacters() {
            if !npc.isVampire && npc.isAlive {
                let shouldSleep = Double.random(in: 0...1) < sleepChance
                npc.isSleeping = shouldSleep
            }
        }
    }
    
    func generateEvent(scene: Scene, isNight: Bool) -> String? {
        guard let vampireNatureRevealService = vampireNatureRevealService else {
            print("VampireNatureRevealService is nil")
            return nil
        }
        
        let availableEvents = events.filter { event in
            print(event.id)
            // Check time of day
            guard event.time == (isNight ? "night" : "day") else { return false }
            
            // Check NPC count
            let npcCount = scene.getCharacters().count
            guard npcCount >= event.minNPCs && npcCount <= event.maxNPCs else { return false }
            
            // Check required genders
            if !event.requiredGenders.isEmpty {
                let hasRequiredGender = scene.getCharacters().contains { npc in
                    event.requiredGenders.contains(npc.sex.rawValue)
                }
                guard hasRequiredGender else { return false }
            }
            
            // Check required professions
            if !event.requiredProfessions.isEmpty {
                let hasRequiredProfession = scene.getCharacters().contains { npc in
                    event.requiredProfessions.contains(npc.profession.rawValue)
                }
                guard hasRequiredProfession else { return false }
            }
            
            // Check required ages
            if !event.requiredAges.isEmpty {
                let hasRequiredAge = scene.getCharacters().contains { npc in
                    npc.age >= event.requiredAges[0] && npc.age <= event.requiredAges[1]
                }
                guard hasRequiredAge else { return false }
            }
            
            // Check sleeping state
            if event.sleepingRequired {
                let hasSleepingNPC = scene.getCharacters().contains { $0.isSleeping }
                guard hasSleepingNPC else { return false }
            }
            
            // Check location type
            guard event.isIndoors == scene.isIndoor else { return false }
            
            // Check awareness level
            let awareness = vampireNatureRevealService.getAwareness(for: scene.id)
            guard Float(awareness) >= Float(event.minAwareness) && Float(awareness) <= Float(event.maxAwareness) else { return false }
            
            return true
        }
        
        guard let selectedEvent = availableEvents.randomElement() else { return nil }
        
        // Replace placeholders with actual values
        var eventText = selectedEvent.template
        let availableNPCs = scene.getCharacters().shuffled()
        
        // Replace NPC placeholders
        for i in 1...10 {
            let placeholder = "{NPC\(i)}"
            if eventText.contains(placeholder) {
                if i <= availableNPCs.count {
                    eventText = eventText.replacingOccurrences(of: placeholder, with: availableNPCs[i-1].name)
                }
            }
        }
        
        // Replace location placeholder
        eventText = eventText.replacingOccurrences(of: "{LOCATION}", with: scene.name)
        
        return eventText
    }
    
    func broadcastEvent(_ eventText: String) {
        DispatchQueue.main.async { [weak self] in
            self?.gameEventsBus?.addEventMessage(eventText)
        }
    }
}

// MARK: - Data Models
private struct EventsData: Codable {
    let events: [EventTemplate]
}

private struct EventTemplate: Codable {
    let id: String
    let time: String
    let minNPCs: Int
    let maxNPCs: Int
    let requiredGenders: [String]
    let requiredProfessions: [String]
    let requiredAges: [Int]
    let minBloodLevel: Int
    let maxBloodLevel: Int
    let sleepingRequired: Bool
    let isIndoors: Bool
    let minAwareness: Int
    let maxAwareness: Int
    let template: String
    
    enum CodingKeys: String, CodingKey {
        case id, time, minNPCs, maxNPCs, requiredGenders, requiredProfessions, requiredAges
        case minBloodLevel, maxBloodLevel, sleepingRequired, isIndoors
        case minAwareness, maxAwareness, template
    }
} 
