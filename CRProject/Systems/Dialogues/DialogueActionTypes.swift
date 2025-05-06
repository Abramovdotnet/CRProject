//
//  DialogueActionTypes.swift
//  CRProject
//
//  Created by Abramov Anatoliy on [Current Date]. 
//

import Foundation

/// Defines the target of a dialogue action.
enum ActionTarget: String, Codable {
    case player // Action affects the player character
    case npc    // Action affects the NPC involved in the dialogue
    case global // Action affects a global game state variable
    // TODO: Add other targets if needed (e.g., location, item)
}

/// Identifies specific stats or flags that can be modified by dialogue actions.
enum StatIdentifier: String, Codable {
    // NPC Specific
    case relationship
    case isIntimidated // Could use 0 for false, 1 for true
    // TODO: Add other NPC stats (e.g., specific mood, suspicion level)

    // Player Specific
    case coins
    case health
    // TODO: Add other player stats/flags
    
    // Global
    case awareness // Vampire Nature Reveal Service awareness
    case gameFlag // For setting arbitrary game flags (value could be 1/0)
    case questStatus // Value could represent quest stage
    // TODO: Add other global stats/flags
}

/// Represents a single action to be executed as a result of a dialogue choice.
struct DialogueAction: Codable, Equatable {
    let type: ActionType
    let parameters: [String: ActionParameterValue] // Using a dictionary for flexible parameters

    // Define the types of actions available
    enum ActionType: String, Codable {
        case modifyStat
        case triggerGameEvent
        // TODO: Add other action types (e.g., addItem, setLocationFlag)
    }
    
    // Helper to make parameters Codable while allowing different underlying types
    enum ActionParameterValue: Codable, Equatable {
        case string(String)
        case int(Int)
        case bool(Bool)
        case double(Double)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else {
                throw DecodingError.typeMismatch(ActionParameterValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported parameter type"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value): try container.encode(value)
            case .int(let value): try container.encode(value)
            case .bool(let value): try container.encode(value)
            case .double(let value): try container.encode(value)
            }
        }
        
        // Convenience getters (optional)
        var stringValue: String? { if case .string(let val) = self { return val }; return nil }
        var intValue: Int? { if case .int(let val) = self { return val }; return nil }
        var boolValue: Bool? { if case .bool(let val) = self { return val }; return nil }
        var doubleValue: Double? { if case .double(let val) = self { return val }; return nil }
    }
    
    // Convenience static constructors for common actions
    static func modifyStat(target: ActionTarget, stat: StatIdentifier, value: Int) -> DialogueAction {
        return DialogueAction(type: .modifyStat, parameters: [
            "target": .string(target.rawValue),
            "stat": .string(stat.rawValue),
            "value": .int(value)
        ])
    }
    
    static func triggerGameEvent(name: String, params: [String: ActionParameterValue] = [:]) -> DialogueAction {
        var fullParams = params
        fullParams["eventName"] = .string(name)
        return DialogueAction(type: .triggerGameEvent, parameters: fullParams)
    }
} 