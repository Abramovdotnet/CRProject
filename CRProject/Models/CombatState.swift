import Foundation

struct CombatState {
    var participants: [CombatParticipant]
    var initiator: CombatParticipant
    var type: CombatType
    var phase: CombatPhase
    var history: [CombatAction]
    var result: CombatResult?
} 