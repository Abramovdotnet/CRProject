//
//  Player.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//
import Foundation

class Player: Character {
    let id: UUID = UUID()
    var name: String = ""
    var sex: Sex = .male
    var age: Int = 0
    var profession: Profession = .adventurer
    let bloodMeter: BloodMeter = BloodMeter(initialBlood: 30.0)
    var isVampire: Bool { true }
    var isAlive: Bool { bloodMeter.currentBlood > 0 }
    var isUnknown: Bool = false
    
    init(name: String, sex: Sex, age: Int, profession: Profession) {
        self.name = name
        self.sex = sex
        self.age = age
        self.profession = profession
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
