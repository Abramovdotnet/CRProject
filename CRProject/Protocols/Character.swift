//
//  ICharacter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

protocol Character : ObservableObject, Codable {
    var id: UUID { get }
    var name: String { get set }
    var sex: Sex { get set }
    var age: Int { get set }
    var profession: String { get set }
    var bloodMeter: BloodMeter { get }
    var isVampire: Bool { get }
}
