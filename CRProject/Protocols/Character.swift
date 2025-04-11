//
//  ICharacter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

protocol Character: Identifiable, ObservableObject, Codable {
    var id: Int{ get }
    var name: String { get }
    var sex: Sex { get }
    var age: Int { get }
    var profession: Profession { get }
    var isVampire: Bool { get }
    var isAlive: Bool { get }
    var bloodMeter: BloodMeter { get }
    var isUnknown: Bool { get set }
    var isIntimidated: Bool { get set }
    var intimidationDay: Int { get set }
    var index : Int { get set }
    var isBeasy: Bool { get set }
    var homeLocationId: Int { get set }
    var currentLocationId: Int { get set }
    
    func shareBlood(amount: Float, from donor: any Character)
}
