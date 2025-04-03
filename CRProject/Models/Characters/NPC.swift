//
//  NPC.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

class NPC: Character {
    var id: UUID = UUID()
    var name: String = ""
    var sex: Sex = .male
    var age: Int = 0
    var profession: Profession = .adventurer
    let bloodMeter: BloodMeter = BloodMeter(initialBlood: 100.0)
    var isVampire: Bool = false
    var isAlive: Bool { bloodMeter.currentBlood > 0 }
    var isUnknown: Bool = true
    var isSleeping: Bool = false
    
    init() {}
    
    init(name: String, sex: Sex, age: Int, profession: Profession, isVampire: Bool, id: UUID) {
        self.name = name
        self.sex = sex
        self.age = age
        self.profession = profession
        self.id = id
        self.isVampire = isVampire
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
}
