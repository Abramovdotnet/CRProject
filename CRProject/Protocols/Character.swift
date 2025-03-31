//
//  ICharacter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

protocol Character: ObservableObject, Codable {
    var id: UUID { get }
    var name: String { get }
    var sex: Sex { get }
    var age: Int { get }
    var profession: Profession { get }
    var isVampire: Bool { get }
    var isAlive: Bool { get }
    var bloodMeter: BloodMeter { get }
    var isUnknown: Bool { get set }
    
    func shareBlood(amount: Float, from donor: any Character)
}
