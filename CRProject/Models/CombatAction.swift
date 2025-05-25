import Foundation

enum CombatActionType: Int {
    case attack = 0
    case defend = 1
    case useItem = 2
    case escape = 3
    case ability = 4
    // Новые действия для вампира
    case feed = 5
    case dominate = 6
    case shadowStep = 7
    case drain = 8
    
    var icon: String {
        switch self {
        case .attack: return "flame"
        case .feed: return "mouth.fill"
        case .dominate: return "eye"
        case .drain: return "drop.triangle.fill"
        default: return "questionmark"
        }
    }
    var displayName: String {
        switch self {
        case .attack: return "Attack"
        case .feed: return "Bite"
        case .dominate: return "Dominate"
        case .drain: return "Drain"
        default: return "Action"
        }
    }
    // Краткое описание последствий (здоровье +/-)
    var consequenceDescription: String {
        switch self {
        case .attack: return "+25/-25 HP"
        case .feed: return "+25 HP, -25 HP"
        case .dominate: return "Dominate (no damage)"
        case .drain: return "Kill & absorb all blood"
        default: return ""
        }
    }
}

struct CombatAction {
    let type: CombatActionType
    let initiatorId: String
    let targetId: String?
    let parameters: [String: Any]?
} 
