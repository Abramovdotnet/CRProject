//
//  Relationship.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 16.04.2025.
//
import Foundation
import Combine

class Relationship: ObservableObject, Codable {
    @Published var state : RelationshipState = .neutral
    @Published var value: Int = 0 {
        didSet {
            updateState()
        }
    }
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
        value = min(max(amount, Relationship.MIN_VALUE), Relationship.MAX_VALUE)
    }
    
    enum CodingKeys: String, CodingKey {
        case state, value
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Int.self, forKey: .value)
        state = try container.decodeIfPresent(RelationshipState.self, forKey: .state) ?? RelationshipState.getState(value: value)
        if state != RelationshipState.getState(value: value) {
             state = RelationshipState.getState(value: value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(state, forKey: .state)
    }
    
    init() {
        self.value = 0
        self.state = .neutral
    }
}

class NPCRelationship : Relationship {
    var npcId : Int = 0
    
    enum NPCCodingKeys: String, CodingKey {
        case npcId
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NPCCodingKeys.self)
        npcId = try container.decode(Int.self, forKey: .npcId)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NPCCodingKeys.self)
        try container.encode(npcId, forKey: .npcId)
        try super.encode(to: encoder)
    }
    
    init(npcId: Int, value: Int = 0) {
        self.npcId = npcId
        super.init()
        self.value = value
    }
    
    override required init() {
        self.npcId = 0
        super.init()
    }
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
