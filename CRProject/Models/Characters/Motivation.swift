import SwiftUI

enum Motivation: String, CaseIterable, Codable {
    case community = "Community"
    case ambition = "Ambition"
    case survival = "Survival"
    case knowledge = "Knowledge"
    case order = "Order"
    case craftsmanship = "Craftsmanship"
    case justice = "Justice"
    case faith = "Faith"
    case independence = "Independence"
    case family = "Family"
    case duty = "Duty"
    case adventure = "Adventure"
    case peace = "Peace"
    case service = "Service"
    case spiritualGrowth = "Spiritual growth"
    case leadership = "Leadership"
    case protection = "Protection"
    case wealth = "Wealth"
    case honor = "Honor"
    case skill = "Skill"
    case security = "Security"
    case mystery = "Mystery"
    case glory = "Glory"
    case power = "Power"
    case respect = "Respect"
    case control = "Control"
    case violence = "Violence"
    case logistics = "Logistics"
    case unknown = "Unknown" // Added for potential missing values

    var description: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .community: return "person.3"
        case .ambition: return "arrow.up.forward.circle"
        case .survival: return "figure.walk"
        case .knowledge: return "book.closed"
        case .order: return "list.bullet.rectangle"
        case .craftsmanship: return "hammer"
        case .justice: return "scalemass"
        case .faith: return "hands.sparkles"
        case .independence: return "figure.stand.line.dotted.figure.stand"
        case .family: return "house"
        case .duty: return "shield.checkerboard"
        case .adventure: return "map"
        case .peace: return "leaf"
        case .service: return "person.crop.circle.badge.plus"
        case .spiritualGrowth: return "star.circle"
        case .leadership: return "crown"
        case .protection: return "figure.arms.open"
        case .wealth: return "dollarsign.circle"
        case .honor: return "medal"
        case .skill: return "wrench.and.screwdriver.fill"
        case .security: return "lock.shield"
        case .mystery: return "questionmark.circle"
        case .glory: return "star.fill"
        case .power: return "bolt.fill"
        case .respect: return "hand.thumbsup"
        case .control: return "pianokeys"
        case .violence: return "exclamationmark.triangle"
        case .logistics: return "shippingbox"
        case .unknown: return "questionmark.diamond"
        }
    }

    var color: Color {
        switch self {
        case .community: return .green
        case .ambition: return .orange
        case .survival: return .brown
        case .knowledge: return .blue
        case .order: return .gray
        case .craftsmanship: return .brown
        case .justice: return .yellow
        case .faith: return .purple
        case .independence: return .cyan
        case .family: return .pink
        case .duty: return .blue.opacity(0.7)
        case .adventure: return .green.opacity(0.7)
        case .peace: return .green
        case .service: return .teal
        case .spiritualGrowth: return .indigo
        case .leadership: return .yellow
        case .protection: return .cyan
        case .wealth: return .yellow
        case .honor: return .yellow
        case .skill: return .gray
        case .security: return .gray
        case .mystery: return .purple
        case .glory: return .yellow
        case .power: return .red
        case .respect: return .green
        case .control: return .purple
        case .violence: return .red
        case .logistics: return .brown
        case .unknown: return .secondary
        }
    }
    
    // Failable initializer to handle potential missing or unknown values from JSON
    init?(rawValue: String) {
            switch rawValue {
            case "Community": self = .community
            case "Ambition": self = .ambition
            case "Survival": self = .survival
            case "Knowledge": self = .knowledge
            case "Order": self = .order
            case "Craftsmanship": self = .craftsmanship
            case "Justice": self = .justice
            case "Faith": self = .faith
            case "Independence": self = .independence
            case "Family": self = .family
            case "Duty": self = .duty
            case "Adventure": self = .adventure
            case "Peace": self = .peace
            case "Service": self = .service
            case "Spiritual growth": self = .spiritualGrowth
            case "Leadership": self = .leadership
            case "Protection": self = .protection
            case "Wealth": self = .wealth
            case "Honor": self = .honor
            case "Skill": self = .skill
            case "Security": self = .security
            case "Mystery": self = .mystery
            case "Glory": self = .glory
            case "Power": self = .power
            case "Respect": self = .respect
            case "Control": self = .control
            case "Violence": self = .violence
            case "Logistics": self = .logistics
            default: self = .unknown // Assign unknown if the rawValue doesn't match any known case
            }
        }
} 
