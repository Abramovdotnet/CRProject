import Foundation

struct CombatResult {
    var healthChanges: [String: Int] // id участника -> изменение здоровья
    var bloodChanges: [String: Int] // id участника -> изменение крови
    var statusChanges: [String: [String]] // id участника -> новые статусы
    var relationChanges: [String: [String: Int]] // id -> (id другого -> изменение отношений)
    var summary: String // Краткое описание результата
} 