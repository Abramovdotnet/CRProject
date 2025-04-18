import SwiftUI

enum Morality: String, CaseIterable, Codable {
    case lawfulGood = "Lawful good"
    case lawfulNeutral = "Lawful neutral"
    case lawfulEvil = "Lawful evil" // Added for completeness
    case neutralGood = "Neutral good"
    case neutral = "Neutral" // Also maps "True neutral" if needed, or add separate case
    case neutralEvil = "Neutral evil"
    case chaoticGood = "Chaotic good"
    case chaoticNeutral = "Chaotic neutral"
    case chaoticEvil = "Chaotic evil"
    case trueNeutral = "True neutral" // Explicitly adding True Neutral

    var description: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .lawfulGood: return "shield.lefthalf.filled"
        case .lawfulNeutral: return "shield"
        case .lawfulEvil: return "shield.slash"
        case .neutralGood: return "heart"
        case .neutral: return "circle"
        case .neutralEvil: return "eye.slash"
        case .chaoticGood: return "sparkles"
        case .chaoticNeutral: return "tornado"
        case .chaoticEvil: return "flame"
        case .trueNeutral: return "circle.dashed" // Specific icon for True Neutral
        }
    }

    var color: Color {
        switch self {
        case .lawfulGood: return .blue
        case .lawfulNeutral: return .gray
        case .lawfulEvil: return .purple.opacity(0.8)
        case .neutralGood: return .green
        case .neutral: return .gray.opacity(0.7)
        case .neutralEvil: return .red.opacity(0.7)
        case .chaoticGood: return .yellow
        case .chaoticNeutral: return .orange
        case .chaoticEvil: return .red
        case .trueNeutral: return .white // Specific color for True Neutral
        }
    }
    
    // Initializer to handle potential variations like "Neutral" vs "True neutral" from JSON
    init?(rawValue: String) {
        switch rawValue {
        case "Lawful good": self = .lawfulGood
        case "Lawful neutral": self = .lawfulNeutral
        case "Lawful evil": self = .lawfulEvil
        case "Neutral good": self = .neutralGood
        case "Neutral": self = .neutral // Maps "Neutral" string
        case "True neutral": self = .trueNeutral // Maps "True neutral" string
        case "Neutral evil": self = .neutralEvil
        case "Chaotic good": self = .chaoticGood
        case "Chaotic neutral": self = .chaoticNeutral
        case "Chaotic evil": self = .chaoticEvil
        default: return nil // Or handle unknown cases, maybe default to .neutral?
        }
    }
} 
