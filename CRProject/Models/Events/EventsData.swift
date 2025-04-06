import Foundation

/// Represents a template for generating in-game events
public struct EventTemplate: Codable, Equatable {
    /// Unique identifier for the event template
    public let id: String
    /// Time of day when this event can occur ("day" or "night")
    public let time: String
    /// Minimum number of NPCs required for this event
    public let minNPCs: Int
    /// Maximum number of NPCs allowed for this event
    public let maxNPCs: Int
    /// Required genders for NPCs in this event
    public let requiredGenders: [String]
    /// Required professions for NPCs in this event
    public let requiredProfessions: [String]
    /// Required age range for NPCs in this event [min, max]
    public let requiredAges: [Int]
    /// Minimum blood level required for this event
    public let minBloodLevel: Int
    /// Maximum blood level allowed for this event
    public let maxBloodLevel: Int
    /// Whether sleeping NPCs are required for this event
    public let sleepingRequired: Bool
    /// Whether this event must occur indoors
    public let isIndoors: Bool
    /// Minimum awareness level required for this event
    public let minAwareness: Int
    /// Maximum awareness level allowed for this event
    public let maxAwareness: Int
    /// Type of location required for this event
    public let locationType: String
    /// Type of scene required for this event
    public let sceneType: String
    /// Whether NPC changes are required for this event
    public let npcChangeRequired: Bool
    /// Vampire presence requirement ("required", "forbidden", or "optional")
    public let vampirePresence: String
    /// Template text for the event with placeholders
    public let template: String
    /// Whether this event requires a vampire
    public let requiresVampire: Bool
    /// Whether this event is a death event
    public let isDeathEvent: Bool
    /// Optional awareness increase for this event
    public let awarenessIncrease: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, time, minNPCs, maxNPCs, requiredGenders, requiredProfessions
        case requiredAges, minBloodLevel, maxBloodLevel, sleepingRequired, isIndoors
        case minAwareness, maxAwareness, locationType, sceneType, npcChangeRequired
        case vampirePresence, template, requiresVampire, isDeathEvent
        case awarenessIncrease
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        time = try container.decode(String.self, forKey: .time)
        minNPCs = try container.decode(Int.self, forKey: .minNPCs)
        maxNPCs = try container.decode(Int.self, forKey: .maxNPCs)
        requiredGenders = try container.decode([String].self, forKey: .requiredGenders)
        requiredProfessions = try container.decode([String].self, forKey: .requiredProfessions)
        requiredAges = try container.decode([Int].self, forKey: .requiredAges)
        minBloodLevel = try container.decode(Int.self, forKey: .minBloodLevel)
        maxBloodLevel = try container.decode(Int.self, forKey: .maxBloodLevel)
        sleepingRequired = try container.decode(Bool.self, forKey: .sleepingRequired)
        isIndoors = try container.decode(Bool.self, forKey: .isIndoors)
        minAwareness = try container.decode(Int.self, forKey: .minAwareness)
        maxAwareness = try container.decode(Int.self, forKey: .maxAwareness)
        locationType = try container.decode(String.self, forKey: .locationType)
        sceneType = try container.decode(String.self, forKey: .sceneType)
        npcChangeRequired = try container.decode(Bool.self, forKey: .npcChangeRequired)
        vampirePresence = try container.decode(String.self, forKey: .vampirePresence)
        template = try container.decode(String.self, forKey: .template)
        requiresVampire = try container.decodeIfPresent(Bool.self, forKey: .requiresVampire) ?? false
        isDeathEvent = try container.decodeIfPresent(Bool.self, forKey: .isDeathEvent) ?? false
        awarenessIncrease = try container.decodeIfPresent(Int.self, forKey: .awarenessIncrease)
    }
}

/// Container for event templates loaded from JSON
public struct EventsData: Codable {
    /// Array of event templates
    public let events: [EventTemplate]
    
    public static func load() -> EventsData? {
        if let url = Bundle.main.url(forResource: "Events", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let eventsData = try JSONDecoder().decode(EventsData.self, from: data)
                
                // Validate events after loading
                EventValidationService.shared.validateEvents(in: eventsData.events)
                
                return eventsData
            } catch {
                DebugLogService.shared.log("Error decoding events: \(error)", category: "Error")
                return nil
            }
        }
        return nil
    }
} 
