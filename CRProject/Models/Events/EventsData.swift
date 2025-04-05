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
}

/// Container for event templates loaded from JSON
public struct EventsData: Codable {
    /// Array of event templates
    public let events: [EventTemplate]
} 