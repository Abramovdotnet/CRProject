import Foundation

struct CombatConfig: Codable {
    var actionChances: [String: Double] // Тип действия -> шанс успеха
    var damageValues: [String: Int] // Тип действия -> урон
    var consequences: [String: [String: String]] // Тип действия -> (событие -> последствие)
    var allowedTypes: [CombatType]
    // Новые поля для расширенного конфига
    var bloodModifiers: [String: Double]? // low/medium/high -> модификатор
    var witnessChance: Double? // Шанс свидетеля
    var aftermath: AftermathConfig? // Последствия шума и расследования
    var criticalChance: Double? // Шанс критического эффекта
    var criticalEffects: [String: String]? // success/fail -> эффект
    // --- Новые поля ---
    var equipmentModifiers: [String: [String: Int]]? // "weapon"/"armor" -> имя -> бонус
    var bite: [String: CodableValue]? // healPercent, allowedTargets
    var publicBiteReveal: Bool?
    var professionModifiers: [String: [String: CodableValue]]?
}

struct AftermathConfig: Codable {
    var noiseLevel: [String: Double]? // действие -> уровень шума
    var investigationThreshold: Double? // порог для расследования
}

// Для поддержки значений типа Double/Int/String/Array
struct CodableValue: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrVal = try? container.decode([String].self) {
            value = arrVal
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrVal as [String]:
            try container.encode(arrVal)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
} 