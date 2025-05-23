//
//  Player.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//
import Foundation
import Combine

class Player: ObservableObject, Character, Codable {
    // Published properties for UI updates
    @Published var name: String = ""
    @Published var age: Int = 0
    // Assuming BloodMeter is or will be made ObservableObject
    @Published var bloodMeter: BloodMeter = BloodMeter(initialBlood: 100.0)
    @Published var coins: Coins = Coins()
    @Published var currentLocationId: Int = 0
    @Published var items: [Item] = []
    
    var processedRelationshipDialogueNodeOptions: [String] = []

    // Non-Published properties
    var id: Int = 0
    var index : Int = 0
    var sex: Sex = .male
    var profession: Profession = .adventurer
    var isVampire: Bool { true } // Constant
    var isAlive: Bool { bloodMeter.currentBlood > 0 } // Derived
    var isUnknown: Bool = false
    var isIntimidated: Bool = false
    var isBeasyByPlayerAction: Bool = false
    var intimidationDay: Int = 0
    var homeLocationId: Int = 0
    var hiddenAt: HidingCell = .none
    var isInvisible: Bool = false
    var onCraftingProcess: Bool = false
    @Published var isArrested: Bool = false
    @Published var arrestTime: Int = 0

    @Published var desiredVictim: DesiredVictim = DesiredVictim()
    
    var smithingProgress: ProfessionProgress = ProfessionProgress()
    var alchemyProgress: ProfessionProgress = ProfessionProgress()
    var medicineProgress: ProfessionProgress = ProfessionProgress()
    var writingProgress: ProfessionProgress = ProfessionProgress()
    var taloringProgress: ProfessionProgress = ProfessionProgress()

    // --- НОВОЕ СВОЙСТВО ДЛЯ КВЕСТОВ ---
    @Published var activeQuests: [String: PlayerQuestState] = [:] // Словарь [QuestID: State]
    var completedQuestInteractions: Set<String> = [] // Множество ключей завершенных/неповторяемых квестовых взаимодействий
    var completedQuestIDs: Set<String>? = Set()

    // --- Initializer ---
    init(name: String, sex: Sex, age: Int, profession: Profession, id: Int) {
        self.name = name
        self.sex = sex
        self.age = age
        self.profession = profession
        self.id = id
        // Initialization of other properties happens automatically
        self.smithingProgress.profession = .blacksmith
        self.alchemyProgress.profession = .alchemist
    }

    // Default initializer might be needed
    // init() {}

    // --- Methods ---
    func shareBlood(amount: Float, from donor: any Character) {
        if donor.isVampire {
            donor.bloodMeter.useBlood(amount)
        } else {
            let availableBlood = min(amount, donor.bloodMeter.bloodPercentage)
            donor.bloodMeter.useBlood(availableBlood)
            self.bloodMeter.addBlood(availableBlood) // Should trigger update via @Published bloodMeter
        }
    }
    
    func processRelationshipDialogueNode(option: String) {
        if !processedRelationshipDialogueNodeOptions.contains(option) {
            processedRelationshipDialogueNodeOptions.append(option)
        }
    }
    
    func checkIsRelationshipDialogueNodeOptionProcessed(option: String) -> Bool {
        return processedRelationshipDialogueNodeOptions.contains(option)
    }
    
    func arrestPlayer() {
        StatisticsService.shared.increaseTimesArrested()
        isArrested = true
        arrestTime = StatisticsService.shared.timesArrested * 24
    }

    // --- Codable Conformance ---
    enum CodingKeys: String, CodingKey {
        // Include all properties that need saving, published or not
        case id, index, name, sex, age, profession, bloodMeter, coins, isVampire, isAlive, isUnknown, isIntimidated, isBeasyByPlayerAction, intimidationDay, homeLocationId, currentLocationId, hiddenAt, items, desiredVictim, processedRelationshipDialogueNodes, isArrested, arrestTime
        case activeQuests
        case completedQuestInteractions
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode all properties
        id = try container.decode(Int.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)
        name = try container.decode(String.self, forKey: .name)
        sex = try container.decode(Sex.self, forKey: .sex)
        age = try container.decode(Int.self, forKey: .age)
        profession = try container.decode(Profession.self, forKey: .profession)
        bloodMeter = try container.decode(BloodMeter.self, forKey: .bloodMeter)
        coins = try container.decode(Coins.self, forKey: .coins)
        // isVampire is computed, no need to decode
        // isAlive is computed, no need to decode
        isUnknown = try container.decode(Bool.self, forKey: .isUnknown)
        isIntimidated = try container.decode(Bool.self, forKey: .isIntimidated)
        isBeasyByPlayerAction = try container.decode(Bool.self, forKey: .isBeasyByPlayerAction)
        intimidationDay = try container.decode(Int.self, forKey: .intimidationDay)
        homeLocationId = try container.decode(Int.self, forKey: .homeLocationId)
        currentLocationId = try container.decode(Int.self, forKey: .currentLocationId)
        hiddenAt = try container.decode(HidingCell.self, forKey: .hiddenAt)
        items = try container.decode([Item].self, forKey: .items)
        desiredVictim = try container.decode(DesiredVictim.self, forKey: .desiredVictim)
        isArrested = try container.decode(Bool.self, forKey: .isArrested)
        arrestTime = try container.decode(Int.self, forKey: .arrestTime)
        // <<< Декодируем activeQuests, используем decodeIfPresent для обратной совместимости, если сохранений без этого поля еще нет
        activeQuests = try container.decodeIfPresent([String: PlayerQuestState].self, forKey: .activeQuests) ?? [:]
        // <<< Декодируем completedQuestInteractions
        completedQuestInteractions = try container.decodeIfPresent(Set<String>.self, forKey: .completedQuestInteractions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode all properties
        try container.encode(id, forKey: .id)
        try container.encode(index, forKey: .index)
        try container.encode(name, forKey: .name)
        try container.encode(sex, forKey: .sex)
        try container.encode(age, forKey: .age)
        try container.encode(profession, forKey: .profession)
        try container.encode(bloodMeter, forKey: .bloodMeter)
        try container.encode(coins, forKey: .coins)
        // isVampire is computed, no need to encode
        // isAlive is computed, no need to encode
        try container.encode(isUnknown, forKey: .isUnknown)
        try container.encode(isIntimidated, forKey: .isIntimidated)
        try container.encode(isBeasyByPlayerAction, forKey: .isBeasyByPlayerAction)
        try container.encode(intimidationDay, forKey: .intimidationDay)
        try container.encode(homeLocationId, forKey: .homeLocationId)
        try container.encode(currentLocationId, forKey: .currentLocationId)
        try container.encode(hiddenAt, forKey: .hiddenAt)
        try container.encode(items, forKey: .items)
        try container.encode(desiredVictim, forKey: .desiredVictim)
        try container.encode(isArrested, forKey: .isArrested)
        try container.encode(arrestTime, forKey: .arrestTime)
        // <<< Кодируем activeQuests
        try container.encode(activeQuests, forKey: .activeQuests)
        // <<< Кодируем completedQuestInteractions
        try container.encode(completedQuestInteractions, forKey: .completedQuestInteractions)
    }
}
