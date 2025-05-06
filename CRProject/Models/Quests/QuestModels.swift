import Foundation

// --- Основные структуры ---

/// Представляет квест в игре.
struct Quest: Codable, Identifiable {
    /// Уникальный строковый идентификатор квеста (например, "main_01", "guild_fetch_artifact").
    let id: String
    /// Название квеста, отображаемое игроку.
    let title: String
    /// Описание квеста для журнала.
    let description: String
    /// Упорядоченный массив этапов квеста.
    let stages: [QuestStage]
    /// ID NPC, который инициирует квест (опционально).
    let startingNPCId: Int?
    /// Условия, необходимые для начала квеста (опционально).
    let prerequisites: QuestPrerequisites?
    /// Награды за выполнение квеста (опционально).
    let rewards: QuestRewards?
}

/// Представляет отдельный этап (шаг) квеста.
struct QuestStage: Codable, Identifiable {
    /// Уникальный идентификатор этапа в рамках квеста (например, "01_talk_to_mage", "02_find_ruins").
    let id: String
    /// Текст цели этапа, отображаемый игроку (например, "Поговорить с магом Алариком в его башне").
    let objective: String
    /// Имя JSON-файла специфичного диалога, связанного с этим этапом (опционально).
    let dialogueFilename: String?
    /// Опциональный ID NPC, с которым связан этот этап или его диалог.
    let associatedNPCId: Int?
    /// Опциональное имя профессии NPC, для которой предназначен этот этап/диалог.
    let restrictToProfession: String?
    /// Действия, выполняемые при активации этого этапа (например, добавление маркера на карту).
    let activationActions: [DialogueAction]?
    /// Условия, необходимые для завершения этого этапа.
    let completionConditions: [QuestCondition] // Этап должен иметь хотя бы одно условие завершения
    /// Действия, выполняемые при завершении этого этапа (например, выдача награды, запуск следующего этапа).
    let completionActions: [DialogueAction]?
}

// --- Вспомогательные структуры ---

/// Условия для начала квеста.
struct QuestPrerequisites: Codable {
    // let requiredLevel: Int? // УДАЛЕНО
    let requiredCompletedQuests: [String]? // Массив ID квестов, которые должны быть завершены
    let requiredItems: [ItemRequirement]?     // Предметы, которые должны быть у игрока
    let activeQuestStates: [ActiveQuestStateCheck]? // Проверка состояния других квестов
    let requiredGameFlags: [GameFlagCondition]?   // Проверка глобальных флагов
    // Можно добавить другие условия: репутация с фракцией, время суток, погода и т.д.
}

/// Награды за выполнение квеста.
struct QuestRewards: Codable {
    // let experience: Int? // УДАЛЕНО
    let coins: Int?
    let items: [ItemReward]? // Массив ID предметов и их количество
    let rewardActions: [DialogueAction]? // Действия, которые выполняются при получении награды
}

struct QuestRewardItem: Codable {
    let itemId: Int
    let quantity: Int
}

/// Условие для завершения этапа квеста.
struct QuestCondition: Codable {
    let type: QuestConditionType
    let parameters: [String: ActionParameterValue] // Используем существующий ActionParameterValue для гибкости
}

/// Типы условий для завершения этапа квеста.
enum QuestConditionType: String, Codable {
    case talkToNPC // Поговорить с определенным NPC
    case getItem // Получить определенное количество предметов
    case reachLocation // Добраться до определенной локации
    case useItem // Использовать предмет (возможно, в определенном месте)
    case defeatNPC // Победить определенного NPC
    case completeDialogueNode // Достичь определенного узла в диалоге
    case checkGameFlag // Проверить значение глобального флага
    // Добавьте другие типы по мере необходимости
}

// --- Структура для хранения состояния квестов игрока ---

/// Хранит состояние активного квеста у игрока.
struct PlayerQuestState: Codable {
    let questId: String
    var currentStageId: String
    var completedStages: Set<String> = [] // ID завершенных этапов
    var isFailed: Bool = false // <-- Флаг провала квеста
    // var failedRecruitAttempts: Set<Int> = [] // <-- УДАЛЕНО: Плохая идея
    // var stageProgress: [String: Float]? // Опциональный прогресс - пока убрали для простоты

    // Обновляем CodingKeys
    enum CodingKeys: String, CodingKey {
        case questId, currentStageId, completedStages, isFailed // failedRecruitAttempts удалено
    }

    init(questId: String, initialStageId: String) {
        self.questId = questId
        self.currentStageId = initialStageId
    }
    
    // Можно добавить явные init(from:) / encode(to:), если стандартная реализация не сработает
}

// Важно: Убедитесь, что DialogueAction и ActionParameterValue доступны в этом контексте.
// Если они определены в другом модуле, может потребоваться импорт или перенос.
// Сейчас предполагаем, что они доступны глобально или будут импортированы.
// Также DialogueAction и ActionParameterValue должны быть Codable.

// --- НОВЫЕ СТРУКТУРЫ ДЛЯ PREREQUISITES И REWARDS ---
struct ItemRequirement: Codable {
    let itemId: Int // или String
    let quantity: Int
}

struct ActiveQuestStateCheck: Codable {
    let questId: String
    let shouldBeActive: Bool
}

struct GameFlagCondition: Codable {
    let flagName: String
    let expectedValue: Int // или Bool, или String, в зависимости от того, как хранятся флаги
}

struct ItemReward: Codable { // Ранее называлась QuestRewardItem, переименована для консистентности
    let itemId: Int // или String
    let quantity: Int
}

// struct ReputationChange: Codable { // УДАЛЕНО }

// --- Копируем ActionParameterValue сюда для видимости, пока нет импортов ---
// В идеале, это должно быть доступно через импорт модуля или общую область видимости.
enum ActionParameterValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else {
            throw DecodingError.typeMismatch(ActionParameterValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported parameter type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        }
    }
    
    var stringValue: String? { if case .string(let val) = self { return val }; return nil }
    var intValue: Int? { if case .int(let val) = self { return val }; return nil }
    var boolValue: Bool? { if case .bool(let val) = self { return val }; return nil }
    var doubleValue: Double? { if case .double(let val) = self { return val }; return nil }
}
// --- Конец скопированного ActionParameterValue --- 