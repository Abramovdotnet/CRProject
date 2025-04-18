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
    
    func increase(amount: Int) {
        value += amount
        value = value > Relationship.MAX_VALUE ? Relationship.MAX_VALUE : value
    }
    
    func decrease(amount: Int) {
        value -= amount
        value = value < Relationship.MIN_VALUE ? Relationship.MIN_VALUE : value
    }
    
    func setValue(amount: Int) {
        value = max(amount, 100)
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
