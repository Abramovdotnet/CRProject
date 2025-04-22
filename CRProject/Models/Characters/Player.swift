//
//  Player.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//
import Foundation

class Player: Character, Codable {
    var id: Int = 0
    var index : Int = 0
    var name: String = ""
    var sex: Sex = .male
    var age: Int = 0
    var profession: Profession = .adventurer
    private var _bloodMeter: BloodMeter = BloodMeter(initialBlood: 100.0)
    var bloodMeter: BloodMeter {
        get { _bloodMeter }
        set { _bloodMeter = newValue }
    }
    var coins: Coins = Coins()
    var isVampire: Bool { true }
    var isAlive: Bool { bloodMeter.currentBlood > 0 }
    var isUnknown: Bool = false
    var isIntimidated: Bool = false
    var isBeasyByPlayerAction: Bool = false
    var intimidationDay: Int = 0
    var homeLocationId: Int = 0
    var currentLocationId: Int = 0
    var hiddenAt: HidingCell = .none
    
    var desiredVictim: DesiredVictim = DesiredVictim()

    init(name: String, sex: Sex, age: Int, profession: Profession, id: Int) {
        self.name = name
        self.sex = sex
        self.age = age
        self.profession = profession
        self.id = id
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
    
    enum CodingKeys: String, CodingKey {
        case id, name, sex, age, profession, isUnknown, isSleeping, _bloodMeter
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sex = try container.decode(Sex.self, forKey: .sex)
        age = try container.decode(Int.self, forKey: .age)
        profession = try container.decode(Profession.self, forKey: .profession)
        isUnknown = try container.decode(Bool.self, forKey: .isUnknown)
        _bloodMeter = try container.decode(BloodMeter.self, forKey: ._bloodMeter)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sex, forKey: .sex)
        try container.encode(age, forKey: .age)
        try container.encode(profession, forKey: .profession)
        try container.encode(isUnknown, forKey: .isUnknown)
        try container.encode(_bloodMeter, forKey: ._bloodMeter)
    }
}
