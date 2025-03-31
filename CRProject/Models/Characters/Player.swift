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
    var profession: String = ""
    let bloodMeter: BloodMeter = BloodMeter(initialBlood: 0.0)
    var isVampire: Bool { true }
    
    init() {}
    
    init(name: String, sex: Sex, age: Int, profession: String) {
        self.name = name
        self.sex = sex
        self.age = age
        self.profession = profession
    }
}
