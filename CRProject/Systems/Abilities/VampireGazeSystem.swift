//
//  VampireGazeSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 13.04.2025.
//

import SwiftUI

class VampireGazeSystem: GameService {
    static let shared = VampireGazeSystem()
    
    private let gameEventBusService: GameEventsBusService
    private let gameTimeService: GameTimeService
    
    enum GazePower: String, CaseIterable {
        case seduction     // Gentle seduction
        case command // Deep hypnosis
        case dominate  // Forceful control
        case scare // Savage fear
        case follow // Force follow
        case release // Release from effects
        case dreamstealer // Steal dreams to improve relationships
        
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
            
            let gameTimeService: GameTimeService = DependencyManager.shared.resolve()
            let currentDay = gameTimeService.currentDay
            
            if AbilitiesSystem.shared.hasDreamstealer && npc.currentActivity == .sleep && npc.lastDreamStealDay != currentDay {
                availablePowers.append(.dreamstealer)
            }
            
            if AbilitiesSystem.shared.hasEnthralling {
                //availablePowers.append(.seduction)
            }
            
            if GameStateService.shared.player?.isArrested == false {
                availablePowers.append(.scare)
                availablePowers.append(.follow)
            }
            
            // Filter powers based on NPC's current activity
            switch npc.currentActivity {
            case .seductedByPlayer:
                availablePowers = availablePowers.filter { $0 != .seduction && $0 != .follow }
                availablePowers.append(.release)
            case .allyingPlayer:
                availablePowers = availablePowers.filter { $0 != .seduction && $0 != .dominate }
                availablePowers.append(.release)
            case .followingPlayer:
                availablePowers = availablePowers.filter { $0 != .follow }
                availablePowers.append(.release)
            default:
                availablePowers = availablePowers.filter { $0 != .release }
            }
            
            return availablePowers
        }
        
        var icon: String {
            switch self {
            case .seduction: return "heart.fill"
            case .command: return "eye.fill"
            case .dominate: return "bolt.fill"
            case .scare: return "figure.run"
            case .follow: return "person.2.fill"
            case .release: return "lock.open.fill"
            case .dreamstealer: return "bed.double.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .seduction: return .teal
            case .command: return .purple
            case .dominate: return .green
            case .scare: return .red
            case .follow: return .blue
            case .release: return .gray
            case .dreamstealer: return .purple
            }
        }
        
        var description: String {
            switch self {
            case .seduction: return "Gentle seduction, most effective on social NPCs"
            case .command: return "Hypnotic influence, works on weak-willed NPCs"
            case .dominate: return "Forceful control, effective but risky"
            case .scare: return "Savage fear, most effective on weak-willed NPCs"
            case .follow: return "Forces NPC to follow you"
            case .release: return "Release NPC from any vampire influence, returning them to normal"
            case .dreamstealer: return "Steal sleeping NPC's dream to increase relationship by 5"
            }
        }
        
        var cost: Float {
            switch self {
            case .seduction: return 10
            case .command: return 20
            case .dominate: return 10
            case .scare: return 10
            case .follow: return 10
            case .release: return 5
            case .dreamstealer: return 15
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
        case .release:
            successChance = 100 // Always succeeds
            awarenessIncrease = 1
        case .dreamstealer:
            // Dreamstealer is more effective on sleeping NPCs
            if npc.currentActivity == .sleep {
                successChance = 100 - (resistance * 0.5) // Half resistance for sleeping targets
            } else {
                successChance = 0 // Cannot be used on non-sleeping NPCs
            }
            awarenessIncrease = 5 // Low awareness increase as target is asleep
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
            } else if power == .release {
                npc.isBeasyByPlayerAction = false
                npc.isSpecialBehaviorSet = false
                npc.currentActivity = .socialize
                npc.increasePlayerRelationship(with: 1)
                
                gameEventBusService.addMessageWithIcon(
                    message: "Released \(npc.name) from your influence",
                    type: .event,
                    location: GameStateService.shared.currentScene?.name,
                    primaryNPC: npc,
                    interactionType: NPCInteraction.observing,
                    hasSuccess: true,
                    isSuccess: true
                )
                
                NPCInteractionManager.shared.playerInteracted(with: npc)
                return true
            } else if power == .dreamstealer {
                // Leave the NPC sleeping, just steal their dream
                npc.increasePlayerRelationship(with: 5)  // Significant relationship boost
                
                // Track the last day this ability was used on this NPC to enforce once per day limit
                npc.lastDreamStealDay = gameTimeService.currentDay
                
                gameEventBusService.addMessageWithIcon(
                    message: "Stole a pleasant dream from \(npc.name), improving your relationship",
                    type: .event,
                    location: GameStateService.shared.currentScene?.name,
                    primaryNPC: npc,
                    interactionType: NPCInteraction.observing,
                    hasSuccess: true,
                    isSuccess: true
                )
            } else {
                //npc.isIntimidated = true
                //npc.intimidationDay = gameTimeService.currentDay + 1 // Effect lasts till next day
            }
            
            VampireNatureRevealService.shared.increaseAwareness(amount: awarenessIncrease / 3)
            
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
