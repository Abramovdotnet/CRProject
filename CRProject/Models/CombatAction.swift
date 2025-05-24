import Foundation

enum CombatActionType: Int {
    case attack = 0
    case defend = 1
    case useItem = 2
    case escape = 3
    case ability = 4
    // Новые действия для вампира
    case bite = 5
    case dominate = 6
    case shadowStep = 7
}

struct CombatAction {
    let type: CombatActionType
    let initiatorId: String
    let targetId: String?
    let parameters: [String: Any]?
} 