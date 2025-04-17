//
//  Relationship.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 16.04.2025.
//
class Relationship : Codable {
    var state : RelationshipState = .neutral
    var value: Int = 0
    static let MIN_VALUE : Int = -100
    static let MAX_VALUE : Int = 100
    
    private func updateState() {
        state = RelationshipState.getState(value: value)
    }
    
    func increase(value: Int) {
        self.value += value
    }
    
    func decrease(value: Int) {
        self.value -= value
    }
    
    func setValue(_ value: Int) {
        self.value = value
        updateState()
    }
}

class NPCRelationship : Relationship {
    var npcId : Int = 0
}

enum RelationshipState : String, Codable {
    case enemy = "enemy"
    case almostEnemy = "almostEnemy"
    case neutral = "neutral"
    case ally = "ally"
    case friend = "friend"
    
    var description: String {
        return rawValue.capitalized
    }
    
    static func getState(value: Int) -> RelationshipState {
        if value >= 70 {
            return .friend
        } else if value >= 30 && value < 70 {
            return .ally
        } else if value >= -30 && value < 30 {
            return .neutral
        } else if value > -70 && value < -30 {
            return .neutral
        } else if value <= -70 {
            return .enemy
        } else {
            return .neutral
        }
    }
}
