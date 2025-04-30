//
//  NPC.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation
import Combine

class NPC: ObservableObject, Character, Codable {    
    @Published var id: Int = 0
    @Published var index : Int = 0
    @Published var name: String = ""
    @Published var sex: Sex = .male
    @Published var age: Int = 0
    @Published var profession: Profession = .adventurer
    @Published var bloodMeter: BloodMeter = BloodMeter(initialBlood: 100.0)
    @Published var coins: Coins = Coins()
    @Published var morality: Morality = .neutral
    @Published var motivation: Motivation = .community
    @Published var isVampire: Bool = false
    var isAlive: Bool { bloodMeter.currentBlood > 0 }
    var isMilitary: Bool { profession == .militaryOfficer || profession == .guardman || profession == .cityGuard }
    @Published var isUnknown: Bool = true
    @Published var isIntimidated: Bool = false
    @Published var intimidationDay: Int = 0
    @Published var isBeasyByPlayerAction: Bool = false
    @Published var isSpecialBehaviorSet: Bool = false
    @Published var isNpcInteractionBehaviorSet: Bool = false
    @Published var npcInteractionSpecialTime: Int = 0
    @Published var npcInteractionTargetNpcId: Int = 0
    @Published var specialBehaviorTime: Int = 0
    @Published var isVampireAttackWitness = false
    @Published var isCasualtyWitness = false
    @Published var casualtyNpcId : Int = 0
    @Published var isCrimeWitness = false
    @Published var homeLocationId: Int = 0
    @Published var currentLocationId: Int = 0
    @Published var spentNightWithPlayer: Bool = false
    @Published var typicalActivities: [NPCActivityType] = []
    @Published var workActivities: [NPCActivityType] = []
    @Published var leisureActivities: [NPCActivityType] = []
    @Published var currentActivity: NPCActivityType = .idle
    @Published var background: String = ""
    @Published var playerRelationship: Relationship = Relationship()
    @Published var npcsRelationship: [NPCRelationship] = []
    @Published var alliedWithNPC: NPC?
    
    @Published var items: [Item] = []
    
    @Published var lastPlayerInteractionDate: Date = Date()
    @Published var hasInteractedWithPlayer: Bool = false
    
    var currentInteractionNPC: NPC? = nil
    
    @Published var deathStatus: DeathStatus = .none
    
    init() {}
    
    init(name: String, sex: Sex, age: Int, profession: Profession, isVampire: Bool, id: Int) {
        self.name = name
        self.sex = sex
        self.age = age
        self.profession = profession
        self.id = id
        self.isVampire = isVampire
        
        typicalActivities = self.profession.typicalActivities()
        workActivities = self.profession.primaryWorkActivities()
        leisureActivities = self.profession.primaryLeisureActivities()     
    }
    
    func shareBlood(amount: Float, from donor: any Character) {
        if donor.isVampire {
            donor.bloodMeter.useBlood(amount)
        } else {
            let availableBlood = min(amount, donor.bloodMeter.bloodPercentage)
            donor.bloodMeter.useBlood(availableBlood)
            self.bloodMeter.addBlood(availableBlood)
        }
    }
    
    func getDeathStatus() -> DeathStatus {
        let currentStatus = isAlive ? DeathStatus.none : DeathStatus.unknown
        return deathStatus != .none ? deathStatus : currentStatus
    }
    
    func increasePlayerRelationship(with value: Int) {
        let wouldCheckFriendshipStateChange = playerRelationship.state == .neutral
        var finalValue = AbilitiesSystem.shared.hasOldFriend ? value * 2 : value
        
        if AbilitiesSystem.shared.hasUndeadCasanova && spentNightWithPlayer && (playerRelationship.state == .friend || playerRelationship.state == .ally) {
            finalValue += value * 2
        }
        playerRelationship.increase(amount: AbilitiesSystem.shared.hasOldFriend ? value * 2 : value)
        
        if wouldCheckFriendshipStateChange && playerRelationship.state == .friend {
            StatisticsService.shared.incrementFriendshipsCreated()
        }
    }
    
    func decreasePlayerRelationship(with value: Int) {
        playerRelationship.decrease(amount: value)
    }
    
    func increaseNPCRelationship(with value: Int, of npc: NPC) {
        let relationshipIndex = npcsRelationship.firstIndex { $0.npcId == npc.id }
        
        if let index = relationshipIndex {
            npcsRelationship[index].increase(amount: value)
        } else {
            let relationship = NPCRelationship()
            relationship.npcId = npc.id
            relationship.increase(amount: value)
            
            npcsRelationship.append(relationship)
        }
    }
    
    func decreaseNPCRelationship(with value: Int, of npc: NPC) {
        let relationshipIndex = npcsRelationship.firstIndex { $0.npcId == npc.id }
        
        if let index = relationshipIndex {
            npcsRelationship[index].decrease(amount: value)
        } else {
            let relationship = NPCRelationship()
            relationship.npcId = npc.id
            relationship.decrease(amount: value)
            
            npcsRelationship.append(relationship)
        }
    }
    
    func getNPCRelationshipValue(of npc: NPC) -> Int {
        let relationshipIndex = npcsRelationship.firstIndex { $0.npcId == npc.id }
        
        if let index = relationshipIndex {
            return npcsRelationship[index].value
        } else {
            return 0
        }
    }
    
    func getNPCRelationshipState(of npc: NPC) -> RelationshipState? {
        let relationshipIndex = npcsRelationship.firstIndex { $0.npcId == npc.id }
        
        if let index = relationshipIndex {
            return npcsRelationship[index].state
        } else {
            return nil
        }
    }
    
    var isFirstConversation: Bool {
        return !hasInteractedWithPlayer
    }
    
    enum CodingKeys: String, CodingKey {
        case id, index, name, sex, age, profession, bloodMeter, coins, morality, motivation
        case isVampire, isUnknown, isIntimidated, intimidationDay, isBeasyByPlayerAction
        case isSpecialBehaviorSet, isNpcInteractionBehaviorSet, npcInteractionSpecialTime, npcInteractionTargetNpcId
        case specialBehaviorTime, isVampireAttackWitness, isCasualtyWitness, casualtyNpcId, isCrimeWitness
        case homeLocationId, currentLocationId, typicalActivities, workActivities, leisureActivities
        case currentActivity, background, playerRelationship, npcsRelationship, items, lastPlayerInteractionDate
        case deathStatus, hasInteractedWithPlayer, spentNightWithPlayer, providedAlibis
        case alliedWithNPCId
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)
        name = try container.decode(String.self, forKey: .name)
        sex = try container.decode(Sex.self, forKey: .sex)
        age = try container.decode(Int.self, forKey: .age)
        profession = try container.decode(Profession.self, forKey: .profession)
        bloodMeter = try container.decode(BloodMeter.self, forKey: .bloodMeter)
        coins = try container.decode(Coins.self, forKey: .coins)
        morality = try container.decode(Morality.self, forKey: .morality)
        motivation = try container.decode(Motivation.self, forKey: .motivation)
        isVampire = try container.decode(Bool.self, forKey: .isVampire)
        isUnknown = try container.decode(Bool.self, forKey: .isUnknown)
        isIntimidated = try container.decode(Bool.self, forKey: .isIntimidated)
        intimidationDay = try container.decode(Int.self, forKey: .intimidationDay)
        isBeasyByPlayerAction = try container.decode(Bool.self, forKey: .isBeasyByPlayerAction)
        isSpecialBehaviorSet = try container.decode(Bool.self, forKey: .isSpecialBehaviorSet)
        isNpcInteractionBehaviorSet = try container.decode(Bool.self, forKey: .isNpcInteractionBehaviorSet)
        npcInteractionSpecialTime = try container.decode(Int.self, forKey: .npcInteractionSpecialTime)
        npcInteractionTargetNpcId = try container.decode(Int.self, forKey: .npcInteractionTargetNpcId)
        specialBehaviorTime = try container.decode(Int.self, forKey: .specialBehaviorTime)
        isVampireAttackWitness = try container.decode(Bool.self, forKey: .isVampireAttackWitness)
        isCasualtyWitness = try container.decode(Bool.self, forKey: .isCasualtyWitness)
        casualtyNpcId = try container.decode(Int.self, forKey: .casualtyNpcId)
        isCrimeWitness = try container.decode(Bool.self, forKey: .isCrimeWitness)
        homeLocationId = try container.decode(Int.self, forKey: .homeLocationId)
        currentLocationId = try container.decode(Int.self, forKey: .currentLocationId)
        
        if let spentNightValue = try? container.decode(Bool.self, forKey: .spentNightWithPlayer) {
            spentNightWithPlayer = spentNightValue
        }
        
        typicalActivities = try container.decode([NPCActivityType].self, forKey: .typicalActivities)
        workActivities = try container.decode([NPCActivityType].self, forKey: .workActivities)
        leisureActivities = try container.decode([NPCActivityType].self, forKey: .leisureActivities)
        currentActivity = try container.decode(NPCActivityType.self, forKey: .currentActivity)
        background = try container.decode(String.self, forKey: .background)
        playerRelationship = try container.decode(Relationship.self, forKey: .playerRelationship)
        npcsRelationship = try container.decode([NPCRelationship].self, forKey: .npcsRelationship)
        items = try container.decode([Item].self, forKey: .items)
        lastPlayerInteractionDate = try container.decode(Date.self, forKey: .lastPlayerInteractionDate)
        deathStatus = try container.decode(DeathStatus.self, forKey: .deathStatus)
        hasInteractedWithPlayer = try container.decode(Bool.self, forKey: .hasInteractedWithPlayer)
        
        if let alliedWithNPCId = try? container.decode(Int.self, forKey: .alliedWithNPCId) {
            // This will be resolved after all NPCs are loaded
            DebugLogService.shared.log("NPC \(id) is allied with NPC \(alliedWithNPCId)", category: "NPC")
        }
    }
    
    func isTradeAvailable() -> Bool {
        return profession == .blacksmith || profession == .alchemist || profession == .bookseller || profession == .barmaid || profession == .herbalist || profession == .merchant || profession == .tavernKeeper || profession == .tailor
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(index, forKey: .index)
        try container.encode(name, forKey: .name)
        try container.encode(sex, forKey: .sex)
        try container.encode(age, forKey: .age)
        try container.encode(profession, forKey: .profession)
        try container.encode(bloodMeter, forKey: .bloodMeter)
        try container.encode(coins, forKey: .coins)
        try container.encode(morality, forKey: .morality)
        try container.encode(motivation, forKey: .motivation)
        try container.encode(isVampire, forKey: .isVampire)
        try container.encode(isUnknown, forKey: .isUnknown)
        try container.encode(isIntimidated, forKey: .isIntimidated)
        try container.encode(intimidationDay, forKey: .intimidationDay)
        try container.encode(isBeasyByPlayerAction, forKey: .isBeasyByPlayerAction)
        try container.encode(isSpecialBehaviorSet, forKey: .isSpecialBehaviorSet)
        try container.encode(isNpcInteractionBehaviorSet, forKey: .isNpcInteractionBehaviorSet)
        try container.encode(npcInteractionSpecialTime, forKey: .npcInteractionSpecialTime)
        try container.encode(npcInteractionTargetNpcId, forKey: .npcInteractionTargetNpcId)
        try container.encode(specialBehaviorTime, forKey: .specialBehaviorTime)
        try container.encode(isVampireAttackWitness, forKey: .isVampireAttackWitness)
        try container.encode(isCasualtyWitness, forKey: .isCasualtyWitness)
        try container.encode(casualtyNpcId, forKey: .casualtyNpcId)
        try container.encode(isCrimeWitness, forKey: .isCrimeWitness)
        try container.encode(homeLocationId, forKey: .homeLocationId)
        try container.encode(currentLocationId, forKey: .currentLocationId)
        try container.encode(typicalActivities, forKey: .typicalActivities)
        try container.encode(workActivities, forKey: .workActivities)
        try container.encode(leisureActivities, forKey: .leisureActivities)
        try container.encode(currentActivity, forKey: .currentActivity)
        try container.encode(background, forKey: .background)
        try container.encode(playerRelationship, forKey: .playerRelationship)
        try container.encode(npcsRelationship, forKey: .npcsRelationship)
        try container.encode(items, forKey: .items)
        try container.encode(lastPlayerInteractionDate, forKey: .lastPlayerInteractionDate)
        try container.encode(deathStatus, forKey: .deathStatus)
        try container.encode(hasInteractedWithPlayer, forKey: .hasInteractedWithPlayer)
        try container.encode(spentNightWithPlayer, forKey: .spentNightWithPlayer)
        
        try container.encodeIfPresent(alliedWithNPC?.id, forKey: .alliedWithNPCId)
    }
}
