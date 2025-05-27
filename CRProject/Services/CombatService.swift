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
        let incomingDamage = 15
        let baseChance: Double = getBaseChance(for: action.type)
        let roll = Double.random(in: 0...1)
        let isSuccess = roll < baseChance
        switch action.type {
        case .attack:
            if isSuccess {
                action.target.bloodMeter.useBlood(Float(outgoingDamage))
                resultSummary = "Success: damage_caused (\(action.target.name)) (-\(outgoingDamage) HP)"
            } else {
                player.bloodMeter.useBlood(Float(incomingDamage))
                resultSummary = "Fail: player_damaged (-\(incomingDamage) HP)"
            }
        case .feed:
            if isSuccess {
                do {
                    try FeedingService.shared.feedOnCharacter(vampire: player, prey: npc, amount: Float(outgoingDamage), in: player.currentLocationId, advanceTime: false)
                    resultSummary = "Success: target_bited (+\(outgoingDamage) HP)"
                } catch {
                    resultSummary = "Fail: feed_error"
                }
            } else {
                player.bloodMeter.useBlood(Float(incomingDamage))
                let awakeNpcsCount = GameStateService.shared.getAwakeNpcsCount()
                
                if awakeNpcsCount > 1 {
                    let awarenessGainValue = FeedingService.shared.calculateFeedAwarenessGainValue(prey: npc)
                    VampireNatureRevealService.shared.increaseAwareness(amount: awarenessGainValue)
                } else {
                    VampireNatureRevealService.shared.increaseAwareness(amount: 5)
                }
                resultSummary = "Fail: player_damaged (-\(incomingDamage) HP)"
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
                resultSummary = "Fail: player_damaged (-\(incomingDamage) HP)"
            }
        case .dominate:
            // Доминирование — только summary/статус, урона нет
            resultSummary = isSuccess ? "Success: npc_dominated" : "Fail: no_effect"
        default:
            resultSummary = "Fail: no_effect"
        }

        if !action.target.isAlive {
            action.target.currentActivity = .casualty
            action.target.deathStatus = .unknown
            action.target.isSpecialBehaviorSet = false
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
    
    // MARK: - Group Combat System
    
    private(set) var assistants: [NPC] = []
    private(set) var combatRound: Int = 0
    
    func startGroupCombat(player: Player, primaryNpc: NPC, assistants: [NPC]) {
        self.player = player
        self.npc = primaryNpc
        self.assistants = assistants
        self.combatRound = 0
        self.history = []
        self.resultSummary = nil
        
        // Подготавливаем всех NPC к бою
        prepareNpc(npc: primaryNpc)
        assistants.forEach { prepareNpc(npc: $0) }
    }
    
    func performGroupAction(_ action: CombatAction) {
        guard let _ = player, let _ = npc else { return }
        
        combatRound += 1
        history.append(action)
        
        let aliveEnemies = getAllAliveEnemies()
        let enemyCount = aliveEnemies.count
        
        // Базовые значения урона
        let baseOutgoingDamage = 25
        let baseIncomingDamage = 15
        
        // Модификаторы в зависимости от количества врагов
        let difficultyMultiplier = calculateDifficultyMultiplier(enemyCount: enemyCount)
        let modifiedIncomingDamage = Int(Float(baseIncomingDamage) * difficultyMultiplier)
        let baseChance = getGroupCombatChance(for: action.type, enemyCount: enemyCount)
        
        let roll = Double.random(in: 0...1)
        let isSuccess = roll < baseChance
        
        switch action.type {
        case .attack:
            handleGroupAttack(
                target: action.target,
                isSuccess: isSuccess,
                outgoingDamage: baseOutgoingDamage,
                incomingDamage: modifiedIncomingDamage,
                aliveEnemies: aliveEnemies
            )
            
        case .feed:
            handleGroupFeed(
                target: action.target,
                isSuccess: isSuccess,
                outgoingDamage: baseOutgoingDamage,
                incomingDamage: modifiedIncomingDamage,
                aliveEnemies: aliveEnemies
            )
            
        case .drain:
            handleGroupDrain(
                target: action.target,
                isSuccess: isSuccess,
                incomingDamage: modifiedIncomingDamage,
                aliveEnemies: aliveEnemies
            )
            
        case .dominate:
            handleGroupDominate(
                target: action.target,
                isSuccess: isSuccess,
                aliveEnemies: aliveEnemies
            )
            
        default:
            resultSummary = "Fail: no_effect"
        }
        
        // Проверяем состояние после действия
        updateCombatState()
    }
    
    private func getAllAliveEnemies() -> [NPC] {
        var enemies = [npc].compactMap { $0 }
        enemies.append(contentsOf: assistants)
        return enemies.filter { $0.isAlive }
    }
    
    private func calculateDifficultyMultiplier(enemyCount: Int) -> Float {
        // Увеличиваем сложность в зависимости от количества врагов
        return 1.0 + Float(enemyCount - 1) * 0.2 // +20% за каждого дополнительного врага
    }
    
    func getGroupCombatChance(for type: CombatActionType, enemyCount: Int) -> Double {
        let baseChance = getBaseChance(for: type)
        let penalty = Double(enemyCount - 1) * 0.05 // -5% за каждого дополнительного врага
        return max(0.1, baseChance - penalty) // Минимум 10% шанс
    }
    
    private func handleGroupAttack(target: NPC, isSuccess: Bool, outgoingDamage: Int, incomingDamage: Int, aliveEnemies: [NPC]) {
        if isSuccess {
            target.bloodMeter.useBlood(Float(outgoingDamage))
            resultSummary = "Success: damage_caused (\(target.name)) (-\(outgoingDamage) HP)"
        } else {
            // При неудаче игрок может получить урон от нескольких врагов
            let attackingEnemies = min(aliveEnemies.count, 3) // Максимум 3 врага атакуют
            let totalDamage = incomingDamage * attackingEnemies
            
            player?.bloodMeter.useBlood(Float(totalDamage))
            
            if attackingEnemies > 1 {
                resultSummary = "Fail: overwhelmed by \(attackingEnemies) enemies (-\(totalDamage) HP)"
            } else {
                resultSummary = "Fail: player_damaged (-\(totalDamage) HP)"
            }
        }
    }
    
    private func handleGroupFeed(target: NPC, isSuccess: Bool, outgoingDamage: Int, incomingDamage: Int, aliveEnemies: [NPC]) {
        guard let player = player else { return }
        
        if isSuccess {
            do {
                try FeedingService.shared.feedOnCharacter(
                    vampire: player,
                    prey: target,
                    amount: Float(outgoingDamage),
                    in: player.currentLocationId,
                    advanceTime: false
                )
                resultSummary = "Success: fed on \(target.name) (+\(outgoingDamage) HP)"
            } catch {
                resultSummary = "Fail: feed_error"
            }
        } else {
            // При неудачном кормлении в группе - больше внимания и урона
            let attackingEnemies = min(aliveEnemies.count, 2)
            let totalDamage = incomingDamage * attackingEnemies
            
            player.bloodMeter.useBlood(Float(totalDamage))
            
            // Увеличенное внимание из-за свидетелей
            let awarenessGain = aliveEnemies.count * 3
            VampireNatureRevealService.shared.increaseAwareness(amount: Float(awarenessGain))
            
            resultSummary = "Fail: feeding interrupted by \(attackingEnemies) enemies (+\(awarenessGain) awareness)"
        }
    }
    
    private func handleGroupDrain(target: NPC, isSuccess: Bool, incomingDamage: Int, aliveEnemies: [NPC]) {
        guard let player = player else { return }
        
        if isSuccess {
            do {
                try FeedingService.shared.emptyBlood(
                    vampire: player,
                    prey: target,
                    in: player.currentLocationId,
                    advanceTime: false
                )
                resultSummary = "Success: drained \(target.name) completely"
            } catch {
                resultSummary = "Fail: drain_error"
            }
        } else {
            // Дрейн - самое опасное действие в группе
            let attackingEnemies = aliveEnemies.count
            let totalDamage = incomingDamage * attackingEnemies
            
            player.bloodMeter.useBlood(Float(totalDamage))
            resultSummary = "Fail: all \(attackingEnemies) enemies attack (-\(totalDamage) HP)"
        }
    }
    
    private func handleGroupDominate(target: NPC, isSuccess: Bool, aliveEnemies: [NPC]) {
        if isSuccess {
            // Успешное доминирование может временно вывести врага из боя
            target.currentActivity = .duzzled
            resultSummary = "Success: \(target.name) dominated (temporarily out of combat)"
        } else {
            // При неудаче доминирования - только потеря времени, но враги могут стать агрессивнее
            resultSummary = "Fail: domination failed, enemies become more aggressive"
        }
    }
    
    private func updateCombatState() {
        guard let player = player else { return }
        
        // Обновляем состояние мертвых NPC
        getAllAliveEnemies().forEach { enemy in
            if !enemy.isAlive {
                enemy.currentActivity = .casualty
                enemy.deathStatus = .unknown
                enemy.isSpecialBehaviorSet = false
            }
        }
        
        // Проверяем смерть игрока
        if !player.isAlive {
            GameStateService.shared.endGame()
        }
    }
    
    func getGroupCombatStatus() -> (aliveEnemies: Int, totalEnemies: Int, round: Int) {
        let aliveEnemies = getAllAliveEnemies()
        let totalEnemies = ([npc].compactMap { $0 } + assistants).count
        return (aliveEnemies.count, totalEnemies, combatRound)
    }
} 
