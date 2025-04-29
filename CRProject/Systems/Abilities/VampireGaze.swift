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
        case seduction     // Gentle seduction
        case command // Deep hypnosis
        case dominate  // Forceful control
        case scare // Savage fear
        case follow // Force follow
        
        static func availableCases(npc: NPC) -> [GazePower] {
            var availablePowers: [GazePower] = []
            
            if AbilitiesSystem.shared.hasSeduction {
                availablePowers.append(.seduction)
            }
            
            if AbilitiesSystem.shared.hasCommand {
                availablePowers.append(.command)
            }
            
            if AbilitiesSystem.shared.hasDomination {
                availablePowers.append(.dominate)
            }
            
            if AbilitiesSystem.shared.hasEnthralling {
                //availablePowers.append(.seduction)
            }
            
            availablePowers.append(.scare)
            availablePowers.append(.follow)
            
            if npc.currentActivity == .seductedByPlayer {
                return availablePowers.filter( { $0 != .seduction && $0 != .follow })
            } else if npc.currentActivity == .allyingPlayer {
                return availablePowers.filter( { $0 != .seduction && $0 != .dominate })
            } else if npc.currentActivity == .followingPlayer {
                return availablePowers.filter( { $0 != .follow })
            } else {
                return availablePowers
            }
        }
        
        var icon: String {
            switch self {
            case .seduction: return "heart.fill"
            case .command: return "eye.fill"
            case .dominate: return "bolt.fill"
            case .scare: return "figure.run"
            case .follow: return "person.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .seduction: return .teal
            case .command: return .purple
            case .dominate: return .green
            case .scare: return .red
            case .follow: return .blue
            }
        }
        
        var description: String {
            switch self {
            case .seduction: return "Gentle seduction, most effective on social NPCs"
            case .command: return "Hypnotic influence, works on weak-willed NPCs"
            case .dominate: return "Forceful control, effective but risky"
            case .scare: return "Savage fear, most effective on weak-willed NPCs"
            case .follow: return "Forces NPC to follow you"
            }
        }
        
        var cost: Float {
            switch self {
            case .seduction: return 10
            case .command: return 20
            case .dominate: return 10
            case .scare: return 10
            case .follow: return 10
            }
        }
    }
    
    init() {
        self.gameEventBusService = DependencyManager.shared.resolve()
        self.gameTimeService = DependencyManager.shared.resolve()
    }
    
    func calculateNPCResistance(npc: NPC) -> Float {
        var resistance: Float = 100.0 - (100.0 - npc.bloodMeter.currentBlood)
        
        // Base modifiers
        if gameTimeService.isNightTime { resistance -= 20 }
        
        // Activity-based modifiers
        switch npc.currentActivity {
        case .drink: resistance -= 20
        case .sleep: resistance -= 30
        case .pray: resistance += 25
        case .patrol: resistance += 15
        case .guardPost: resistance += 15
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
        case .seduction:
            successChance = 100 - resistance
            awarenessIncrease = 10
        case .command:
            successChance = 100 - resistance
            awarenessIncrease = 10
        case .dominate:
            successChance = 100 - resistance
            awarenessIncrease = 20
        case .scare:
            successChance = 100 - resistance
            awarenessIncrease = 20
        case .follow:
            successChance = 100 - resistance
            awarenessIncrease = 15
        }
        
        let roll = Float.random(in: 0...100)
        //let success = roll <= successChance
        let success = true
        
        if success {
            npc.isBeasyByPlayerAction = true
            
            if power == .scare {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .fleeing
                npc.decreasePlayerRelationship(with: 5)
            } else if power == .seduction {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .seductedByPlayer
                npc.increasePlayerRelationship(with: 1)
                StatisticsService.shared.increasePeopleSeducted()
            } else if power == .dominate {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .allyingPlayer
                npc.increasePlayerRelationship(with: 2)
                StatisticsService.shared.increasePeopleDominated()
            } else if power == .follow {
                npc.isSpecialBehaviorSet = true
                npc.specialBehaviorTime = 4
                npc.currentActivity = .followingPlayer
            } else {
                //npc.isIntimidated = true
                //npc.intimidationDay = gameTimeService.currentDay + 1 // Effect lasts till next day
            }
            
            gameEventBusService.addMessageWithIcon(
                message: "Successfully used \(power.rawValue) on \(npc.name)",
                type: .event,
                location: GameStateService.shared.currentScene?.name,
                primaryNPC: npc,
                interactionType: NPCInteraction.observing,
                hasSuccess: true,
                isSuccess: true
            )
        } else {
            VampireNatureRevealService.shared.increaseAwareness(amount: awarenessIncrease)
            npc.decreasePlayerRelationship(with: 10)
            
            gameEventBusService.addMessageWithIcon(
                message: "Failed to use \(power.rawValue) on \(npc.name)",
                type: .danger,
                location: GameStateService.shared.currentScene?.name,
                primaryNPC: npc,
                interactionType: NPCInteraction.observing,
                hasSuccess: true,
                isSuccess: false
            )
        }
        
        NPCInteractionManager.shared.playerInteracted(with: npc)
        
        return success
    }
} 
