import Foundation

struct CombatParticipant {
    let id: String // Может быть playerID или npcID
    let isPlayer: Bool
    // Ссылка на сущность (Player или NPC) можно реализовать через enum или протокол
    // Пока просто id и флаг
    var health: Int
    var blood: Int
    var morale: Int
    var name: String
    var profession: Profession
    var items: [Int] // ID предметов
    var statuses: [String]
    var relations: [String: Int] // id другого участника -> уровень отношений
} 
