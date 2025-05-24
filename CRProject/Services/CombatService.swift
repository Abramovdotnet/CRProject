import Foundation

final class CombatService {
    static let shared = CombatService()
    
    private init() {
        loadConfig()
    }
    
    // Текущее состояние боя (если бой активен)
    private(set) var currentCombatState: CombatState?
    private(set) var config: CombatConfig?
    
    // MARK: - Инициация боя
    func startCombat(with participants: [CombatParticipant], type: CombatType, initiator: CombatParticipant) {
        let state = CombatState(
            participants: participants,
            initiator: initiator,
            type: type,
            phase: .preparation,
            history: [],
            result: nil
        )
        currentCombatState = state
        // Можно отправить Notification/Callback для UI
    }
    
    // MARK: - Завершение боя
    func endCombat(result: CombatResult) {
        guard var state = currentCombatState else { return }
        state.result = result
        state.phase = .aftermath
        currentCombatState = state
        // TODO: Обновить состояние мира, игрока, NPC по результату
        // Можно отправить Notification/Callback для UI
    }
    
    // MARK: - Загрузка конфига
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: "combat_config", withExtension: "json") else {
            print("[CombatService] combat_config.json not found")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(CombatConfig.self, from: data)
            self.config = config
            print("[CombatService] Combat config loaded")
        } catch {
            print("[CombatService] Failed to load config: \(error)")
        }
    }
    
    // MARK: - Обработка действия в бою
    func performAction(_ action: CombatAction) {
        guard var state = currentCombatState, let config = config else { return }
        var history = state.history
        history.append(action)
        
        // Получаем инициатора
        guard let initiatorIdx = state.participants.firstIndex(where: { $0.id == action.initiatorId }) else { return }
        let initiator = state.participants[initiatorIdx]
        // Получаем цель
        let targetIdx = state.participants.firstIndex(where: { $0.id == action.targetId })
        let target = targetIdx != nil ? state.participants[targetIdx!] : nil
        // --- Расчёт шанса успеха ---
        let actionKey = String(describing: action.type)
        var baseChance = config.actionChances[actionKey] ?? 0.0
        // Blood modifier (только для игрока)
        if initiator.isPlayer, let bloodMods = config.bloodModifiers {
            let bloodLevel = initiator.blood
            let mod: Double
            if bloodLevel < 30 { mod = bloodMods["low"] ?? 0.0 }
            else if bloodLevel < 70 { mod = bloodMods["medium"] ?? 0.0 }
            else { mod = bloodMods["high"] ?? 0.0 }
            baseChance += mod
        }
        // --- Критический успех/провал ---
        let isCritical = config.criticalChance != nil ? (Double.random(in: 0...1) < config.criticalChance!) : false
        let roll = Double.random(in: 0...1)
        let isSuccess = isCritical ? true : (roll < baseChance)
        // --- Применение урона и последствий ---
        var healthChanges: [String: Int] = [:]
        var summary = ""
        var consequence: String = ""
        if isCritical, let critEff = config.criticalEffects {
            if isSuccess {
                consequence = critEff["success"] ?? ""
                summary = "Критический успех! "
            } else {
                consequence = critEff["fail"] ?? ""
                summary = "Критический провал! "
            }
        } else {
            if let cons = config.consequences[actionKey] {
                consequence = isSuccess ? (cons["success"] ?? "") : (cons["fail"] ?? "")
            }
        }
        // --- Расчёт урона с учётом экипировки и профессии ---
        var initiatorWeaponBonus = 0
        var targetArmor = 0
        var professionMod: Double = 1.0
        if let t = target, let profMods = config.professionModifiers?[t.profession.rawValue.lowercased() ?? ""] {
            if let val = profMods["damageTaken"]?.value as? Double {
                professionMod = val
            }
        }
        if actionKey == "attack" || actionKey == "bite" {
            // Оружие игрока
            if let weaponId = initiator.items.first,
               let weapon = ItemReader.shared.getItem(by: weaponId),
               let weaponMods = config.equipmentModifiers?["weapon"],
               let bonus = weaponMods[weapon.name] {
                initiatorWeaponBonus = bonus
            }
            // Броня цели
            if let t = target,
               let armorId = t.items.first,
               let armor = ItemReader.shared.getItem(by: armorId),
               let armorMods = config.equipmentModifiers?["armor"],
               let armorBonus = armorMods[armor.name] {
                targetArmor = armorBonus
            }
        }
        // --- Итоговый урон ---
        var damage = 0
        if isSuccess, let tid = action.targetId, let baseDmg = config.damageValues[actionKey] {
            damage = Int((Double(baseDmg + initiatorWeaponBonus - targetArmor) * professionMod).rounded())
            if damage < 0 { damage = 0 }
            healthChanges[tid] = (healthChanges[tid] ?? 0) - damage
        }
        // --- Укус: лечение игрока ---
        var bloodChanges: [String: Int] = [:]
        if isSuccess, actionKey == "bite", let healPercent = config.bite?["healPercent"] as? Double, let tid = action.targetId {
            let heal = Int(Double(damage) * healPercent)
            healthChanges[initiator.id] = (healthChanges[initiator.id] ?? 0) + heal
            bloodChanges[initiator.id] = (bloodChanges[initiator.id] ?? 0) + heal
        }
        // --- Обновление состояния ---
        // Применяем изменения здоровья к участникам
        for (id, delta) in healthChanges {
            if let idx = state.participants.firstIndex(where: { $0.id == id }) {
                state.participants[idx].health += delta
                if state.participants[idx].health < 0 { state.participants[idx].health = 0 }
            }
        }
        for (id, delta) in bloodChanges {
            if let idx = state.participants.firstIndex(where: { $0.id == id }) {
                state.participants[idx].blood += delta
                if state.participants[idx].blood < 0 { state.participants[idx].blood = 0 }
            }
        }
        let result = CombatResult(
            healthChanges: healthChanges,
            bloodChanges: bloodChanges,
            statusChanges: [:],
            relationChanges: [:],
            summary: summary + (isSuccess ? "Успех" : "Провал") + (consequence.isEmpty ? "" : ": " + consequence)
        )
        state.history = history
        state.phase = .result
        state.result = result
        currentCombatState = state
        // Можно отправить Notification/Callback для UI
    }
} 
