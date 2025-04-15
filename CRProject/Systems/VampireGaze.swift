//
//  VampireGazeSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 13.04.2025.
//

import SwiftUI

class VampireGaze: GameService {
    static let shared = VampireGaze()
    
    private let gameEventBusService: GameEventsBusService
    private let gameTimeService: GameTimeService
    
    enum GazePower: String, CaseIterable {
        case charm     // Gentle seduction
        case mesmerize // Deep hypnosis
        case dominate  // Forceful control
        case scare // Savage fear
        case follow // Force follow
        
        static func availableCases(npc: NPC) -> [GazePower] {
            if npc.isIntimidated {
                return npc.currentActivity == .fleeing ? [.mesmerize] : [.scare, .follow]
            } else {
                if npc.currentActivity != .fleeing {
                    return [.charm, .mesmerize, .dominate, .scare, .follow]
                } else {
                    return [.charm, .mesmerize, .dominate]
                }
            }
        }
        
        var icon: String {
            switch self {
            case .charm: return "heart.fill"
            case .mesmerize: return "eye.fill"
            case .dominate: return "bolt.fill"
            case .scare: return "figure.run"
            case .follow: return "person.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .charm: return .teal
            case .mesmerize: return .purple
            case .dominate: return .green
            case .scare: return .red
            case .follow: return .blue
            }
        }
        
        var description: String {
            switch self {
            case .charm: return "Gentle seduction, most effective on social NPCs"
            case .mesmerize: return "Hypnotic influence, works on weak-willed NPCs"
            case .dominate: return "Forceful control, effective but risky"
            case .scare: return "Savage fear, most effective on weak-willed NPCs"
            case .follow: return "Forces NPC to follow you"
            }
        }
        
        var cost: Float {
            switch self {
            case .charm: return 20
            case .mesmerize: return 30
            case .dominate: return 40
            case .scare: return 10
            case .follow: return 20
            }
        }
    }
    
    init() {
        self.gameEventBusService = DependencyManager.shared.resolve()
        self.gameTimeService = DependencyManager.shared.resolve()
    }
    
    func calculateNPCResistance(npc: NPC) -> Float {
        var resistance: Float = 100.0
        
        // Base modifiers
        if gameTimeService.isNightTime { resistance -= 10 }
        if npc.isIntimidated { resistance -= 15 }
        
        // Activity-based modifiers
        switch npc.currentActivity {
        case .drink: resistance -= 20
        case .sleep: resistance -= 30
        case .pray: resistance += 25
        case .patrol: resistance += 15
        default: break
        }
        
        // Profession-based susceptibility
        switch npc.profession {
        case .courtesan, .barmaid:
            resistance -= 15
        case .guardman, .cityGuard:
            resistance += 20
        case .priest, .monk:
            resistance += 30
        case .lordLady, .militaryOfficer:
            resistance += 10
        default:
            break
        }
        
        return max(0, min(100, resistance))
    }
    
    func attemptGazePower(power: GazePower, on npc: NPC) -> Bool {
        let resistance = calculateNPCResistance(npc: npc)
        var successChance: Float = 0
        var awarenessIncrease: Float = 0
        
        switch power {
        case .charm:
            successChance = 70 - resistance * 0.5
            awarenessIncrease = 5
        case .mesmerize:
            successChance = 60 - resistance * 0.6
            awarenessIncrease = 10
        case .dominate:
            successChance = 50 - resistance * 0.7
            awarenessIncrease = 15
        case .scare:
            successChance = 50 - resistance * 0.7
            awarenessIncrease = 15
        case .follow:
            successChance = 50 - resistance * 0.7
            awarenessIncrease = 15
        }
        
        let roll = Float.random(in: 0...100)
        //let success = roll <= successChance
        let success = true
        
        if success {
            npc.isBeasy = true
            
            if power == .scare {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .fleeing
            } else if power == .charm {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .seductedByPlayer
            } else if power == .dominate {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .allyingPlayer
            } else if power == .follow {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .followingPlayer
            } else {
                npc.isIntimidated = true
                npc.intimidationDay = gameTimeService.currentDay + 1 // Effect lasts till next day
            }
            
            gameEventBusService.addMessageWithIcon(
                message: "Successfully used \(power.rawValue) on \(npc.name)",
                icon: power.icon,
                iconColor: power.color,
                type: .event
            )
        } else {
            VampireNatureRevealService.shared.increaseAwareness(for: npc.currentLocationId, amount: awarenessIncrease)
            
            gameEventBusService.addMessageWithIcon(
                message: "Failed to use \(power.rawValue) on \(npc.name)",
                icon: power.icon,
                iconColor: power.color,
                type: .danger
            )
        }
        
        return success
    }
} 
