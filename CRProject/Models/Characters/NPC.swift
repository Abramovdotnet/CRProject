//
//  NPC.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation
import Combine

class NPC: Character {    
    var id: Int = 0
    var index : Int = 0
    var name: String = ""
    var sex: Sex = .male
    var age: Int = 0
    var profession: Profession = .adventurer
    let bloodMeter: BloodMeter = BloodMeter(initialBlood: 100.0)
    var morality: Morality = .neutral
    var motivation: Motivation = .community
    var isVampire: Bool = false
    var isAlive: Bool { bloodMeter.currentBlood > 0 }
    var isMilitary: Bool { profession == .militaryOfficer || profession == .guardman || profession == .cityGuard }
    var isUnknown: Bool = true
    var isIntimidated: Bool = false
    var intimidationDay: Int = 0
    var isBeasyByPlayerAction: Bool = false
    var isSpecialBehaviorSet: Bool = false
    var isNpcInteractionBehaviorSet: Bool = false
    var npcInteractionSpecialTime: Int = 0
    var npcInteractionTargetNpcId: Int = 0
    var specialBehaviorTime: Int = 0
    var isVampireAttackWitness = false
    var isCasualtyWitness = false
    var casualtyNpcId : Int = 0
    var isCrimeWitness = false
    var homeLocationId: Int = 0
    var currentLocationId: Int = 0
    var typicalActivities: [NPCActivityType] = []
    var workActivities: [NPCActivityType] = []
    var leisureActivities: [NPCActivityType] = []
    var currentActivity: NPCActivityType = .idle
    var background: String = ""
    var playerRelationship: Relationship = Relationship()
    var npcsRelationship: [NPCRelationship] = []
    var alliedWithNPC: NPC?
    
    var lastPlayerInteractionDate: Date = Date()
    
    var currentInteractionNPC: NPC? = nil
    
    var deathStatus: DeathStatus = .none
    
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
        if deathStatus != .none {
            return deathStatus
        } else {
            return isAlive ? .none : .unknown
        }
    }
    
    func increasePlayerRelationship(with value: Int) {
        playerRelationship.increase(amount: value)
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
}
