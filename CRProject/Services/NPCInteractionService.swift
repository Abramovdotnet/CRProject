//
//  NPCInteractionService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 13.04.2025.
//

import SwiftUI

class NPCInteractionService : GameService {
    private let gameEventBusService: GameEventsBusService
    private let gameTimeService: GameTimeService
    private let vampireNatureRevealService: VampireNatureRevealService
    
    // Cache for interaction messages and icons
    private let interactionMessages: [NPCInteraction: (message: String, icon: String, color: Color)] = [
        .service: ("serving", NPCActivityType.serve.icon, NPCActivityType.serve.color),
        .patrol: ("stops", NPCActivityType.patrol.icon, NPCActivityType.patrol.color),
        .drunkFight: ("starts to fights with", "figure.boxing", NPCActivityType.drink.color),
        .gambleFight: ("starts to fights with", "figure.boxing", NPCActivityType.drink.color),
        .argue: ("argues with", "captions.bubble.fill", Color.orange),
        .prostitution: ("have a good time with", NPCActivityType.love.icon, NPCActivityType.love.color),
        .flirt: ("flirt with", NPCActivityType.flirt.icon, NPCActivityType.flirt.color),
        .smithingCraft: ("completed smithing order for", NPCActivityType.craft.icon, NPCActivityType.craft.color),
        .alchemyCraft: ("completed alchemy order for", NPCActivityType.craft.icon, NPCActivityType.craft.color),
        .awareAboutVampire: ("warns about vampire attack", NPCActivityType.fleeing.icon, NPCActivityType.fleeing.color),
        .findOutCasualty: ("just found dead corpse of", NPCActivityType.casualty.icon, NPCActivityType.casualty.color),
        .awareAboutCasualty: ("reports about casualty", NPCActivityType.casualty.icon, NPCActivityType.casualty.color),
        .askForProtection: ("hires for protection", NPCActivityType.protect.icon, NPCActivityType.protect.color),
        .trade: ("trade goods with", NPCActivityType.sell.icon, NPCActivityType.sell.color),
        .conversation: ("shares humors with", NPCActivityType.socialize.icon, NPCActivityType.socialize.color)
    ]
    
    init() {
        self.gameEventBusService = DependencyManager.shared.resolve()
        self.gameTimeService = DependencyManager.shared.resolve()
        self.vampireNatureRevealService = VampireNatureRevealService.shared
    }
    
    func handleNPCInteractionsBehavior() {
        // Use lazy collections and early filtering
        let scenes = LocationReader.getLocations()
            .lazy
            .filter { $0.npcCount() > 1 }
        
        for scene in scenes {
            let npcs = scene.getNPCs().filter { $0.currentActivity != .sleep && !$0.isSpecialBehaviorSet}
            
            for npc in npcs {
                // Skip if already interacting
                if npc.currentInteractionNPC != nil {
                    npc.currentInteractionNPC = nil
                    continue
                }
                
                // Skip behavior evaluation for dead npcs
                if !npc.isAlive {
                    continue
                }
                
                // Find potential targets using a more efficient filter
                let potentialTargets = npcs.filter { otherNPC in
                    otherNPC.id != npc.id &&
                    otherNPC.currentInteractionNPC == nil &&
                    !otherNPC.isNpcInteractionBehaviorSet &&
                    isInteractionPossible(currentNPC: npc, otherNPC: otherNPC)
                }
                
                // Prioritize casualty discovery
                let target = potentialTargets.first(where: { !$0.isAlive }) ?? potentialTargets.randomElement()
                
                if let target = target {
                    // Set up the interaction
                    npc.currentInteractionNPC = target
                    target.currentInteractionNPC = npc
                    
                    // Trigger the interaction event
                    triggerInteractionEvent(scene: scene, currentNPC: npc, otherNPC: target)
                }
            }
        }
    }
    
    private func isInteractionPossible(currentNPC: NPC, otherNPC: NPC) -> Bool {
        return currentNPC.isAlive &&
               currentNPC.currentActivity != .sleep &&
               otherNPC.currentActivity != .sleep &&
               otherNPC.currentActivity != .fleeing
    }
    
    private func triggerInteractionEvent(scene: Scene, currentNPC: NPC, otherNPC: NPC) {
        let interaction = NPCInteraction.getPossibleInteraction(
            currentNPC: currentNPC,
            otherNPC: otherNPC,
            gameTimeService: gameTimeService,
            currentScene: scene
        )
        
        guard interaction != .observing else { return }
        
        if let (message, icon, color) = interactionMessages[interaction] {
            gameEventBusService.addMessageWithIcon(
                message: "\(currentNPC.name), \(currentNPC.profession.rawValue) \(message) \(otherNPC.name), \(otherNPC.profession.rawValue) at \(scene.name.capitalized). Relation: \(currentNPC.getNPCRelationshipValue(of: otherNPC)), State: \(currentNPC.getNPCRelationshipState(of: otherNPC)?.description ?? "Unknown")",
                icon: icon,
                iconColor: color,
                type: .common
            )
        }
        
        // Handle special cases
        switch interaction {
        case .drunkFight, .gambleFight:
            handleFightInteraction(currentNPC: currentNPC, otherNPC: otherNPC)
        case .awareAboutVampire:
            handleVampireAwareness(otherNPC: otherNPC)
        case .findOutCasualty:
            handleCasualtyDiscovery(currentNPC: currentNPC, otherNPC: otherNPC)
        case .awareAboutCasualty:
            handleCasualtyAwareness(currentNPC: currentNPC)
        case .flirt:
            handleFlirtInteraction(currentNPC: currentNPC, otherNPC: otherNPC, scene: scene)
        case .askForProtection:
            handleAskForProtection(currentNPC: currentNPC, otherNPC: otherNPC)
        case .conversation:
            handleConversation(currentNPC: currentNPC, otherNPC: otherNPC)
        case .prostitution:
            handleProstitution(currentNPC: currentNPC, otherNPC: otherNPC)
        case .argue:
            handleArgue(currentNPC: currentNPC, otherNPC: otherNPC)
        case .patrol:
            handlePatrol(currentNPC: currentNPC, otherNPC: otherNPC)
        case .smithingCraft, .alchemyCraft:
            handleCraft(currentNPC: currentNPC, otherNPC: otherNPC)
        case .trade:
            handleTrade(currentNPC: currentNPC, otherNPC: otherNPC)
        case .gameOver:
            vampireNatureRevealService.increaseAwareness(for: scene.id, amount: 100.0)
        default:
            break
        }
    }
    
    private func handleFightInteraction(currentNPC: NPC, otherNPC: NPC) {
        let currentNPCHasAdvantage = (currentNPC.profession == .guardman || currentNPC.profession == .cityGuard) &&
            (otherNPC.profession != .guardman && otherNPC.profession != .cityGuard)
        var successCap = currentNPCHasAdvantage ? 30 : 50
        
        if currentNPC.alliedWithNPC != nil {
  
            if currentNPC.alliedWithNPC?.currentActivity == .protect {
                successCap -= 20
            } else {
                successCap -= 10
            }
        }
        let currentNPCWon = Int.random(in: 0...100) > successCap
        
        if currentNPCWon {
            currentNPC.bloodMeter.useBlood(Float.random(in: 10.0...30.0))
            otherNPC.bloodMeter.useBlood(Float.random(in: 30.0...50.0))
        } else {
            currentNPC.bloodMeter.useBlood(Float.random(in: 20.0...50.0))
            otherNPC.bloodMeter.useBlood(Float.random(in: 20.0...50.0))
        }
        
        currentNPC.decreaseNPCRelationship(with: 10, of: otherNPC)
        otherNPC.decreaseNPCRelationship(with: 10, of: currentNPC)
    }
    
    private func handleVampireAwareness(otherNPC: NPC) {
        otherNPC.currentActivity = .fleeing
        otherNPC.isVampireAttackWitness = true
    }
    
    private func handleCasualtyDiscovery(currentNPC: NPC, otherNPC: NPC) {
        currentNPC.isCasualtyWitness = true
        currentNPC.isSpecialBehaviorSet = true
        currentNPC.specialBehaviorTime = 4
        currentNPC.casualtyNpcId = otherNPC.id
        otherNPC.deathStatus = .investigated
    }
    
    private func handleCasualtyAwareness(currentNPC: NPC) {
        currentNPC.isCasualtyWitness = false
        currentNPC.isSpecialBehaviorSet = false
        
        if let casualtyNPC = NPCReader.getRuntimeNPC(by: currentNPC.casualtyNpcId) {
            casualtyNPC.deathStatus = .confirmed
            currentNPC.casualtyNpcId = 0
        }
    }
    
    private func handleAskForProtection(currentNPC: NPC, otherNPC: NPC) {
        var protectionTime = Int.random(in: 3...72)
        otherNPC.isNpcInteractionBehaviorSet = true
        otherNPC.npcInteractionSpecialTime = protectionTime
        otherNPC.npcInteractionTargetNpcId = currentNPC.id
        otherNPC.alliedWithNPC = currentNPC
        currentNPC.alliedWithNPC = otherNPC
        currentNPC.increaseNPCRelationship(with: 10, of: otherNPC)
        otherNPC.increaseNPCRelationship(with: 10, of: currentNPC)
    }
    
    private func handleConversation(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.currentActivity = .socialize
        otherNPC.currentActivity = .socialize
        currentNPC.increaseNPCRelationship(with: 2, of: otherNPC)
        otherNPC.increaseNPCRelationship(with: 2, of: currentNPC)
    }
    
    private func handleProstitution(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.increaseNPCRelationship(with: 5, of: otherNPC)
        otherNPC.increaseNPCRelationship(with: 5, of: currentNPC)
    }
      
    private func handleArgue(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.currentActivity = .socialize
        otherNPC.currentActivity = .socialize
        currentNPC.decreaseNPCRelationship(with: 4, of: otherNPC)
        otherNPC.decreaseNPCRelationship(with: 4, of: currentNPC)
    }
    
    private func handlePatrol(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.decreaseNPCRelationship(with: 2, of: otherNPC)
        otherNPC.decreaseNPCRelationship(with: 2, of: currentNPC)
    }
    
    private func handleCraft(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.increaseNPCRelationship(with: 10, of: otherNPC)
        otherNPC.increaseNPCRelationship(with: 10, of: currentNPC)
    }
    
    private func handleTrade(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.increaseNPCRelationship(with: 3, of: otherNPC)
        otherNPC.increaseNPCRelationship(with: 3, of: currentNPC)
    }
    
    private func handleFlirtInteraction(currentNPC: NPC, otherNPC: NPC, scene: Scene) {
        var flirtCap = 80 - otherNPC.getNPCRelationshipValue(of: currentNPC)
        
        let isSuccessful = Int.random(in: 0...100) > flirtCap
        
        if isSuccessful {
            gameEventBusService.addMessageWithIcon(
                message: "\(currentNPC.name), \(currentNPC.profession.rawValue) flirt with \(otherNPC.name), \(otherNPC.profession.rawValue) at \(scene.name.capitalized)",
                icon: NPCActivityType.flirt.icon,
                iconColor: NPCActivityType.flirt.color,
                type: .common
            )
            otherNPC.increaseNPCRelationship(with: 5, of: currentNPC)
            currentNPC.increaseNPCRelationship(with: 5, of: otherNPC)
        } else {
            gameEventBusService.addMessageWithIcon(
                message: "\(currentNPC.name), \(currentNPC.profession.rawValue) tries to flirts with \(otherNPC.name), \(otherNPC.profession.rawValue) at \(scene.name.capitalized), but beeing rejected",
                icon: "heart.slash",
                iconColor: NPCActivityType.flirt.color,
                type: .common
            )
            
            otherNPC.decreaseNPCRelationship(with: 5, of: currentNPC)
            currentNPC.decreaseNPCRelationship(with: 5, of: otherNPC)
        }
    }
}

enum NPCInteraction : String, CaseIterable, Codable {
    case conversation = "conversation"
    case argue = "argue"
    case service = "service"
    case patrol = "patrol"
    case drunkFight = "drunk fight"
    case gambleFight = "gamble fight"
    case observing = "observing"
    case prostitution = "prostitution"
    case flirt = "flirt"
    case smithingCraft = "smithingCraft"
    case alchemyCraft = "alchemyCraft"
    case awareAboutVampire = "awareAboutVampire"
    case awareAboutCasualty = "awareAboutCasualty"
    case findOutCasualty = "findOutCasualty"
    case askForProtection = "askForProtection"
    case trade = "trade"
    case gameOver = "gameOver"
    
    static func getPossibleInteraction(currentNPC: NPC, otherNPC: NPC, gameTimeService: GameTimeService, currentScene: Scene) -> NPCInteraction {
        var result = NPCInteraction.observing
        
        var availableInteractions: [NPCInteraction] = []
        
        if otherNPC.isAlive && !currentNPC.isCasualtyWitness && !currentNPC.isCrimeWitness {
            // Vampire awareness
            if currentNPC.currentActivity == .fleeing && currentNPC.isVampireAttackWitness && !otherNPC.isVampireAttackWitness {
                return .awareAboutVampire
            }
            
            // Drunk Fight
            if currentNPC.currentActivity == .drink && (!currentNPC.isMilitary && !otherNPC.isMilitary) ||
                (currentNPC.isMilitary && otherNPC.isMilitary){
                var wouldFight = Int.random(in: 0...100) > 95
                
                if wouldFight {
                    availableInteractions.append(.drunkFight)
                }
            }
            // Gamble Fight
            if currentNPC.currentActivity == .gamble && otherNPC.currentActivity == .gamble && (!currentNPC.isMilitary && !otherNPC.isMilitary) ||
                (currentNPC.isMilitary && otherNPC.isMilitary){
                var wouldFight = Int.random(in: 0...100) > 95
                
                if wouldFight {
                    availableInteractions.append(.gambleFight)
                }
            }
            
            // Serve
            if (currentNPC.profession == .tavernKeeper || currentNPC.profession == .servant || currentNPC.profession == .barmaid) && (otherNPC.profession != .tavernKeeper && otherNPC.profession != .servant && otherNPC.profession != .barmaid && otherNPC.profession != .kitchenStaff)
                && (otherNPC.currentActivity == .drink || otherNPC.currentActivity == .eat){
                var wouldOfferService = Int.random(in: 0...100) > 20
                
                availableInteractions.append(wouldOfferService ? .service : .observing)
            }
            
            // Patrol
            if currentNPC.isMilitary && !otherNPC.isMilitary && otherNPC.profession != .lordLady {
                if currentNPC.currentActivity == .patrol || currentNPC.currentActivity == .guardPost {
                    var wouldInteract = Int.random(in: 0...100) > (gameTimeService.isNightTime ? 40 : 70)
                    
                    if wouldInteract {
                        availableInteractions.append(.patrol)
                    }
                }
            }
            
            // Prostitution
            if currentNPC.profession == .courtesan && otherNPC.profession != .courtesan && otherNPC.profession != .tavernKeeper {
                var entertainCap = gameTimeService.isNightTime ? 40 : 90
                var locationMatch = currentScene.sceneType == .tavern || currentScene.sceneType == .brothel || currentScene.isIndoor == false
                
                if locationMatch {
                    entertainCap -= 30
                }
          
                var wouldEntertain = Int.random(in: 0...100) > entertainCap
                
                if wouldEntertain {
                    availableInteractions.append(.prostitution)
                }

            }
            
            // Flirt
            if currentNPC.profession != .priest && otherNPC.profession != .priest && currentNPC.sex != otherNPC.sex && currentNPC.age < 50 && otherNPC.age < 50 {
                var entertainCap = gameTimeService.isNightTime ? 90 : 95
          
                var wouldFlirt = Int.random(in: 0...100) > entertainCap
                
                if wouldFlirt {
                    availableInteractions.append(.flirt)
                }
            }
            
            // Smithing
            if currentNPC.profession == .blacksmith && otherNPC.profession != .blacksmith && otherNPC.profession != .apprentice {
                if currentScene.sceneType == .blacksmith && !gameTimeService.isNightTime {
                    var wouldExecuteOrder = Int.random(in: 0...100) > 30
                    
                    if wouldExecuteOrder {
                        availableInteractions.append(.smithingCraft)
                    }
                }
            }
            
            // Alchemy
            if currentNPC.profession == .alchemist && otherNPC.profession != .alchemist && otherNPC.profession != .apprentice {
                if currentScene.sceneType == .alchemistShop && !gameTimeService.isNightTime {
                    var wouldExecuteOrder = Int.random(in: 0...100) > 30
                    
                    if wouldExecuteOrder {
                        availableInteractions.append(.alchemyCraft)
                    }
                }
            }
            
            // Conversation
            if (currentNPC.currentActivity == otherNPC.currentActivity  ){
                var wouldConversate = Int.random(in: 0...100) > 90
                
                if wouldConversate {
                    var currentRelationship = currentNPC.getNPCRelationshipValue(of: otherNPC)
                    var argueCap = (currentRelationship >= 0 ? (currentRelationship + 70) : (70 - abs(currentRelationship)))
                    
                    var wouldArgue = Int.random(in: 0...100) > Int(argueCap)
                    
                    availableInteractions.append(wouldArgue ? .argue : .conversation)
                }
            }
            
            // Looking for protection
            if currentNPC.bloodMeter.currentBlood < 70 && otherNPC.profession == .mercenary && !otherNPC.isNpcInteractionBehaviorSet {
                var protectionCap = 100 - currentNPC.bloodMeter.currentBlood
                var wouldAskForProtection = Int.random(in: 0...100) > Int(protectionCap)
                
                if wouldAskForProtection {
                    return askForProtection
                }
            }
            
            // Trade
            if currentNPC.currentActivity == .sell {
                if (currentScene.sceneType == .blacksmith || currentScene.sceneType == .alchemistShop || currentScene.sceneType == .bookstore
                    || currentNPC.profession == .merchant) && !gameTimeService.isNightTime {
                    var wouldTrade = Int.random(in: 0...100) > 20
                    
                    if wouldTrade {
                        availableInteractions.append(.trade)
                    }
                }
            }
            
            // If we have any interactions available, pick one randomly
            if !availableInteractions.isEmpty {
                result = availableInteractions.randomElement() ?? .observing
            }
        } else {
            // Find out casualty
            if currentNPC.currentActivity != .casualty && !currentNPC.isCasualtyWitness && !otherNPC.isAlive && otherNPC.getDeathStatus() == .unknown {
                return .findOutCasualty
            }
            // Casualty report
            if currentNPC.currentActivity == .casualty && currentNPC.isCasualtyWitness && otherNPC.isMilitary {
                return .awareAboutCasualty
            }
        }
        
        
        return result
    }
}
