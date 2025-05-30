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
    case marauder    = "Marauder"
    case bear        = "Bear"
    case puma        = "Puma"
    case assassin    = "Assassin"
    case deer        = "Deer"
    case elk         = "Elk"
    case lynx        = "Lynx"
    case whiteWolf   = "White Wolf"
    case roe         = "Roe"
    case none        = "None"
    
    var isHumanoid: Bool {
        switch self {
        case .bandit, .assassin, .marauder:
            return true
        default: return false
        }
    }
    
    var isAggressive: Bool {
        switch self {
        case .bandit, .wolf, .wildBoar, .marauder, .bear, .puma, .assassin, .lynx:
            return true
        default: return false
        }
    }
    
    var baseAttackValue: Int {
        switch self {
        case .bandit: return 10
        case .wolf: return 12
        case .wildBoar: return 12
        case .marauder: return 15
        case .bear: return 25
        case .puma: return 18
        case .assassin: return 20
        case .deer: return 8
        case .elk: return 6
        case .lynx: return 12
        case .whiteWolf: return 15
        case .roe: return 4
        case .none: return 0
        }
    }
    
    var name: String {
        return rawValue
    }
}
