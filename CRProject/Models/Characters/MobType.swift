//
//  MobType.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 28.05.2025.
//

enum MobType: String, CaseIterable, Codable {
    case bandit      = "Bandit"
    case wolf        = "Wolf"
    case wildBoar    = "Wild Boar"
    case bear        = "Bear"
    case none        = "None"
    case puma        = "Puma"
    case assassin    = "Assassin"
    
    var isHumanoid: Bool {
        switch self {
        case .bandit, .assassin:
            return true
        default: return false
        }
    }
    
    var name: String {
        return rawValue
    }
}
