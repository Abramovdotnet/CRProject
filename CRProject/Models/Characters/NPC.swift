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
    var isVampire: Bool = false
    var isAlive: Bool { bloodMeter.currentBlood > 0 }
    var isMilitary: Bool { profession == .militaryOfficer || profession == .guardman || profession == .cityGuard }
    var isUnknown: Bool = true
    var isIntimidated: Bool = false
    var intimidationDay: Int = 0
    var isBeasy: Bool = false
    var isSpecialBehaviorSet: Bool = false
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
}
