import Foundation

final class CombatService {
    static let shared = CombatService()
    
    private init() {}
    
    // Ссылки на реальные объекты
    private(set) var player: Player?
    private(set) var npc: NPC?
    private(set) var history: [CombatAction] = []
    private(set) var resultSummary: String?
    
    func startCombat(player: Player, npc: NPC) {
        prepareNpc(npc: npc)
        self.player = player
        self.npc = npc
        self.history = []
        self.resultSummary = nil
    }
    
    func prepareNpc(npc: NPC) {
        npc.currentActivity = .combat
        npc.isSpecialBehaviorSet = true
    }
    
    func performAction(_ action: CombatAction) {
        guard let player = player, let npc = npc else { return }
        history.append(action)
        let outgoingDamage = 25
        let incomingDamage = 25
        let baseChance: Double = getBaseChance(for: action.type)
        let roll = Double.random(in: 0...1)
        let isSuccess = roll < baseChance
        switch action.type {
        case .attack:
            if isSuccess {
                npc.bloodMeter.useBlood(Float(outgoingDamage))
                resultSummary = "Success: damage_caused"
            } else {
                player.bloodMeter.useBlood(Float(incomingDamage))
                resultSummary = "Fail: player_damaged"
            }
        case .feed:
            if isSuccess {
                do {
                    try FeedingService.shared.feedOnCharacter(vampire: player, prey: npc, amount: Float(outgoingDamage), in: player.currentLocationId, advanceTime: false)
                    resultSummary = "Success: target_bited"
                } catch {
                    resultSummary = "Fail: feed_error"
                }
            } else {
                player.bloodMeter.useBlood(Float(incomingDamage))
                resultSummary = "Fail: player_damaged"
            }
        case .drain:
            if isSuccess {
                do {
                    try FeedingService.shared.emptyBlood(vampire: player, prey: npc, in: player.currentLocationId, advanceTime: false)
                    resultSummary = "Success: target_drained"
                } catch {
                    resultSummary = "Fail: drain_error"
                }
            } else {
                player.bloodMeter.useBlood(Float(incomingDamage))
                resultSummary = "Fail: player_damaged"
            }
        case .dominate:
            // Доминирование — только summary/статус, урона нет
            resultSummary = isSuccess ? "Success: npc_dominated" : "Fail: no_effect"
        default:
            resultSummary = "Fail: no_effect"
        }

        if !npc.isAlive {
            npc.currentActivity = .casualty
            npc.deathStatus = .unknown
        }
        
        if !player.isAlive {
            GameStateService.shared.endGame()
        }
        // Можно добавить обновление UI/Notification
    }
    
    func getBaseChance(for type: CombatActionType) -> Double {
        switch type {
        case .attack: return 0.8
        case .feed: return 0.7
        case .drain: return 0.5
        case .dominate: return 0.5
        default: return 0.5
        }
    }
} 
