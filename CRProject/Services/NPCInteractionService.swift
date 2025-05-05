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
        let scenes = LocationReader.getLocations().filter { $0.sceneType != .town && $0.sceneType != .district }

        for scene in scenes {
            let npcs = scene.getNPCs().filter { $0.currentActivity != .sleep}
            
            // Close / Open doors
            scene.closeOpenLock(isNight: gameTimeService.isNightTime)
            
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
                
                // Find potential targets
                let potentialTargets = npcs.filter { otherNPC in
                    otherNPC.id != npc.id &&
                    otherNPC.currentInteractionNPC == nil &&
                    !otherNPC.isNpcInteractionBehaviorSet &&
                    isInteractionPossible(currentNPC: npc, otherNPC: otherNPC)
                }
                
                var target: NPC?
                
                if npc.isCasualtyWitness {
                    target = potentialTargets.first(where: { $0.isMilitary })
                } else {
                    // Prioritize casualty discovery
                    target = potentialTargets.first(where: { !$0.isAlive }) ?? potentialTargets.randomElement()
                }
                
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
    
    private func triggerStandaloneInteractionEvent(scene: Scene, currentNPC: NPC) {
        let interaction = NPCInteraction.getPossibleStandaloneInteraction(
            currentNPC: currentNPC,
            gameTimeService: gameTimeService,
            currentScene: scene
        )
        
        NPCInteractionEventsService.shared.addEvent(interactionType: interaction, currentNPC: currentNPC, otherNPC: nil, scene: scene, day: gameTimeService.currentDay, hour: gameTimeService.currentHour)
    }
    
    private func triggerInteractionEvent(scene: Scene, currentNPC: NPC, otherNPC: NPC) {
        let interaction = NPCInteraction.getPossibleInteraction(
            currentNPC: currentNPC,
            otherNPC: otherNPC,
            gameTimeService: gameTimeService,
            currentScene: scene
        )
        
        if interaction == .observing {
            let wouldBroadcastStandaloneEvent = Int.random(in: 1...10) > 7
            
            if wouldBroadcastStandaloneEvent {
                triggerStandaloneInteractionEvent(scene: scene, currentNPC: currentNPC)
            }
            return
        }
        
        /*
        if let (message, icon, color) = interactionMessages[interaction] {
            gameEventBusService.addMessageWithIcon(
                message: "\(currentNPC.name), \(currentNPC.profession.rawValue) \(message) \(otherNPC.name), \(otherNPC.profession.rawValue) at \(scene.name.capitalized). Relation: \(currentNPC.getNPCRelationshipValue(of: otherNPC)), State: \(currentNPC.getNPCRelationshipState(of: otherNPC)?.description ?? "Unknown")",
                icon: icon,
                iconColor: color,
                type: .common
            )
        }
        */
        
        var hasSuccess = false
        var isSuccess = false
        
        // Handle special cases
        switch interaction {
        case .drunkFight, .gambleFight:
            isSuccess = handleFightInteraction(currentNPC: currentNPC, otherNPC: otherNPC, reason: interaction)
            hasSuccess = true
        case .awareAboutVampire:
            handleVampireAwareness(otherNPC: otherNPC)
        case .findOutCasualty:
            handleCasualtyDiscovery(currentNPC: currentNPC, otherNPC: otherNPC)
        case .awareAboutCasualty:
            handleCasualtyAwareness(currentNPC: currentNPC, otherNPC: otherNPC)
        case .flirt:
            isSuccess = handleFlirtInteraction(currentNPC: currentNPC, otherNPC: otherNPC, scene: scene)
            hasSuccess = true
        case .askForProtection:
            handleAskForProtection(currentNPC: currentNPC, otherNPC: otherNPC)
        case .conversation:
            handleConversation(currentNPC: currentNPC, otherNPC: otherNPC)
        case .prostitution:
            handleProstitution(currentNPC: currentNPC, otherNPC: otherNPC)
        case .makingLove:
            handleMakingLove(currentNPC: currentNPC, otherNPC: otherNPC)
        case .argue:
            handleArgue(currentNPC: currentNPC, otherNPC: otherNPC)
        case .patrol:
            handlePatrol(currentNPC: currentNPC, otherNPC: otherNPC)
        case .smithingCraft, .alchemyCraft:
            handleCraft(currentNPC: currentNPC, otherNPC: otherNPC)
        case .trade:
            handleTrade(currentNPC: currentNPC, otherNPC: otherNPC)
        case .theft:
            handleTheft(currentNPC: currentNPC, otherNPC: otherNPC)
        case .gameOver:
            vampireNatureRevealService.increaseAwareness(amount: 100.0)
        default:
            break
        }
        
        if hasSuccess {
            NPCInteractionEventsService.shared.addEvent(interactionType: interaction, currentNPC: currentNPC, otherNPC: otherNPC, scene: scene, day: gameTimeService.currentDay, hour: gameTimeService.currentHour, hasSuccess: true, isSuccess: isSuccess)
        } else {
            NPCInteractionEventsService.shared.addEvent(interactionType: interaction, currentNPC: currentNPC, otherNPC: otherNPC, scene: scene, day: gameTimeService.currentDay, hour: gameTimeService.currentHour)
        }
    }
    
    private func handleFightInteraction(currentNPC: NPC, otherNPC: NPC, reason: NPCInteraction) -> Bool {
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
        
        if !currentNPC.isAlive {
            currentNPC.currentActivity = .casualty
            currentNPC.deathStatus = .unknown
        } else if !otherNPC.isAlive {
            otherNPC.currentActivity = .casualty
            otherNPC.deathStatus = .unknown
        }
        
        let militaryNpc = try? LocationReader.getRuntimeLocation(by: currentNPC.currentLocationId).getNPCs().first(where: { $0.isMilitary && $0.id != currentNPC.id && $0.id != otherNPC.id })
        
        if militaryNpc != nil {
            if !currentNPC.isAlive {
                handleArrest(currentNPC: militaryNpc!, otherNPC: otherNPC, reason: reason)
            } else if !otherNPC.isAlive {
                handleArrest(currentNPC: militaryNpc!, otherNPC: currentNPC, reason: reason)
            } else {
                let jailWinner = Int.random(in: 0...10) > 9
                let jailLooser = Int.random(in: 0...10) > 9
                
                if jailWinner {
                    handleArrest(currentNPC: militaryNpc!, otherNPC: currentNPCWon ? currentNPC : otherNPC, reason: reason)
                }
                
                if jailLooser {
                    handleArrest(currentNPC: militaryNpc!, otherNPC: currentNPCWon ? otherNPC : currentNPC, reason: reason)
                }
            }
        }
        
        return currentNPCWon
    }
    
    private func handleVampireAwareness(otherNPC: NPC) {
        otherNPC.currentActivity = .fleeing
        otherNPC.isVampireAttackWitness = true
    }
    
    private func handleCasualtyDiscovery(currentNPC: NPC, otherNPC: NPC) {
        currentNPC.isCasualtyWitness = true
        currentNPC.isSpecialBehaviorSet = true
        currentNPC.specialBehaviorTime = NPCActivityType.casualty.specialBehaviorTime
        currentNPC.casualtyNpcId = otherNPC.id
        otherNPC.deathStatus = .investigated
    }
    
    private func handleCasualtyAwareness(currentNPC: NPC, otherNPC: NPC) {
        currentNPC.isCasualtyWitness = false
        currentNPC.isSpecialBehaviorSet = false
        
        if let casualtyNPC = NPCReader.getRuntimeNPC(by: currentNPC.casualtyNpcId) {
            // Send guard to check
            otherNPC.currentActivity = .patrol
            otherNPC.isNpcInteractionBehaviorSet = true
            otherNPC.npcInteractionTargetNpcId = casualtyNPC.id
            otherNPC.npcInteractionSpecialTime = 8
            
            // Send priest within
            let priest = NPCReader.getNPCs().first(where: { $0.isAlive && $0.profession == .priest || $0.profession == .religiousScholar })
            
            if priest != nil {
                priest?.currentActivity = .pray
                priest?.isNpcInteractionBehaviorSet = true
                priest?.npcInteractionTargetNpcId = casualtyNPC.id
                priest?.npcInteractionSpecialTime = 8
            }
            
            // Send friends
            let friends = NPCReader.getNPCs().filter { $0.isAlive && $0.npcsRelationship.contains(where: { $0.npcId == currentNPC.casualtyNpcId && $0.state == .friend || $0.state == .ally }) }
            
            if friends.count > 0 {
                for friend in friends {
                    friend.currentActivity = .mourn
                    friend.isNpcInteractionBehaviorSet = true
                    friend.npcInteractionTargetNpcId = casualtyNPC.id
                    friend.npcInteractionSpecialTime = 8
                }
            }
            
            casualtyNPC.deathStatus = .confirmed
            currentNPC.casualtyNpcId = 0
            
            PopUpState.shared.show(title: "Casualty reported", details: "Guards arrived to check what happened", image: .system(name: NPCInteraction.findOutCasualty.icon, color: NPCInteraction.findOutCasualty.color))
        }
    }
    
    private func handleAskForProtection(currentNPC: NPC, otherNPC: NPC) {
        let protectionTime = Int.random(in: 3...72)
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
    
    private func handleMakingLove(currentNPC: NPC, otherNPC: NPC)
    {
        currentNPC.increaseNPCRelationship(with: 7, of: otherNPC)
        otherNPC.increaseNPCRelationship(with: 7, of: currentNPC)
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
    
    private func handleArrest(currentNPC: NPC, otherNPC: NPC, reason: NPCInteraction)
    {
        currentNPC.decreaseNPCRelationship(with: 10, of: otherNPC)
        otherNPC.decreaseNPCRelationship(with: 10, of: currentNPC)
        
        let daysJailed = Int.random(in: 1...7)
        
        otherNPC.isNpcInteractionBehaviorSet = true
        otherNPC.npcInteractionSpecialTime = daysJailed * 24
        otherNPC.currentActivity = .jailed
        
        PopUpState.shared.show(title: "Arrest", details: "\(otherNPC.name) has been arrested by \(currentNPC.name) for \(daysJailed) days by \(reason.rawValue)! You could look at him at Dungeon", image: .system(name: NPCInteraction.arrest.icon, color: NPCInteraction.arrest.color))
    }
    
    private func handleTheft(currentNPC: NPC, otherNPC: NPC) {
        let militaryNpc = try? LocationReader.getRuntimeLocation(by: currentNPC.currentLocationId).getNPCs().first(where: { $0.isMilitary && $0.id != currentNPC.id && $0.id != otherNPC.id && $0.currentActivity != .sleep })
        
        var immediateArrest = false
        if militaryNpc != nil {
            immediateArrest = Int.random(in: 0...10) > 7
            
            if immediateArrest {
                handleArrest(currentNPC: currentNPC, otherNPC: militaryNpc!, reason: .theft)
                
                otherNPC.decreaseNPCRelationship(with: 10, of: currentNPC)
                currentNPC.decreaseNPCRelationship(with: 10, of: otherNPC)
            }
        }
        
        if !immediateArrest {
            let aimingToStealItem = Int.random(in: 0...1) == 1
            
            if aimingToStealItem {
                let randomItem = otherNPC.items.filter( {$0.type != .armor && $0.type != .weapon} ).first(where: { $0.cost >= 200 })
                
                if randomItem != nil {
                    ItemsManagementService.shared.moveItem(item: randomItem!, from: otherNPC, to: currentNPC)
                } else {
                    let coinsToStoleAmount = Int.random(in: 50...otherNPC.coins.value)
                    CoinsManagementService.shared.moveCoins(from: otherNPC, to: currentNPC, amount: coinsToStoleAmount)
                }
            } else {
                let coinsStolenAmount = Int.random(in: 50...otherNPC.coins.value)
                CoinsManagementService.shared.moveCoins(from: otherNPC, to: currentNPC, amount: coinsStolenAmount)
            }
        }
    }
    
    private func handleFlirtInteraction(currentNPC: NPC, otherNPC: NPC, scene: Scene) -> Bool {
        let flirtCap = 80 - otherNPC.getNPCRelationshipValue(of: currentNPC)
        let isSuccessful = Int.random(in: 0...100) > flirtCap
        
        if isSuccessful {
            otherNPC.increaseNPCRelationship(with: 5, of: currentNPC)
            currentNPC.increaseNPCRelationship(with: 5, of: otherNPC)
        } else {
            otherNPC.decreaseNPCRelationship(with: 5, of: currentNPC)
            currentNPC.decreaseNPCRelationship(with: 5, of: otherNPC)
        }
        
        return isSuccessful
    }
}

enum NPCInteraction : String, CaseIterable, Codable {
    // couple action
    case conversation = "conversation"
    case argue = "argue"
    case service = "service"
    case patrol = "patrol"
    case drunkFight = "drunk fight"
    case gambleFight = "gamble fight"
    case observing = "observing"
    case prostitution = "prostitution"
    case makingLove = "makingLove"
    case flirt = "flirt"
    case smithingCraft = "smithingCraft"
    case alchemyCraft = "alchemyCraft"
    case awareAboutVampire = "awareAboutVampire"
    case vampireMilitaryReport = "vampireMilitaryReport"
    case awareAboutCasualty = "awareAboutCasualty"
    case findOutCasualty = "findOutCasualty"
    case askForProtection = "askForProtection"
    case trade = "trade"
    case gameOver = "gameOver"
    case arrest = "arrest"
    // standalone actions
    case cleaning = "cleans"
    case drinking = "drinks"
    case eating = "eats"
    case lookingAtMirror = "looking at mirror"
    case suspicioning = "suspicioning"
    case learning = "learning"
    case reading = "reading"
    case praying = "praying"
    case tossingCards = "tossing cards"
    case workingOnSmithingOrder = "working on smithing order"
    case workingOnAlchemyPotion = "working on alchemy potion"
    case checkingCoins = "checking coins"
    case moans = "moans"
    case harvestingFlowers = "harvesting flowers"
    case cleaningWeapon = "cleaning weapon"
    case bathing = "taking a bath"
    case theft = "theft"
    
    var description: String {
        switch self {
        // couple action
        case .conversation:
            return "share humors with"
        case .argue:
            return "argues with"
        case .service:
            return "served"
        case .patrol:
            return "stopped"
        case .drunkFight:
            return "drunk fights with"
        case .gambleFight:
            return "gamble fights with"
        case .observing:
            return "observing"
        case .prostitution:
            return "spent time with"
        case .makingLove:
            return "made love with"
        case .flirt:
            return "flirted with"
        case .smithingCraft:
            return "crafted order for"
        case .alchemyCraft:
            return "boilded potion for"
        case .awareAboutVampire:
            return "spread vampire threat to"
        case .vampireMilitaryReport:
            return "reported vampire threat to"
        case .awareAboutCasualty:
            return "told about casualty"
        case .findOutCasualty:
            return "found dead body of"
        case .askForProtection:
            return "asked for protection"
        case .trade:
            return "made a deal with"
        case .arrest:
            return "arrested"
        case .theft:
            return "stealed goods from"
        case .gameOver:
            return "figure.meditation"
        // standalone actions
        case .cleaning:
            return "cleaning"
        case .drinking:
            return "drinking"
        case .eating:
            return "eating"
        case .lookingAtMirror:
            return "looking at mirror"
        case .suspicioning:
            return "suspicioning"
        case .learning:
            return "learning"
        case .reading:
            return "reading"
        case .praying:
            return "praying"
        case .tossingCards:
            return "tossing cards"
        case .workingOnSmithingOrder:
            return "working on smithing order"
        case .workingOnAlchemyPotion:
            return "working on alchemy potion"
        case .checkingCoins:
            return "checking coins"
        case .moans:
            return "moans"
        case .harvestingFlowers:
            return "harvesting flowers"
        case .cleaningWeapon:
            return "cleaning weapon"
        case .bathing:
            return "taking a bath"
        }
    }
    
    var hasCoinsExchange: Bool {
        if self == .prostitution
            || self == .service
            || self == .smithingCraft
            || self == .alchemyCraft
            ||  self == .trade
            || self == .askForProtection{
            return true
        } else {
            return false
        }
    }
    
    var isStandalone: Bool {
        switch self {
        case .cleaning,
                .drinking,
                .eating,
                .lookingAtMirror,
                .suspicioning,
                .learning,
                .reading,
                .praying,
                .tossingCards,
                .workingOnAlchemyPotion,
                .workingOnSmithingOrder,
                .checkingCoins,
                .moans,
                .harvestingFlowers,
                .cleaningWeapon,
                .bathing:
            return true
        default:
            return false
        }
    }
    
    var interactionBaseCost: Int {
        switch self {
        // couple action
        case .conversation:
            return 0
        case .argue:
            return 0
        case .service:
            return 25
        case .patrol:
            return 0
        case .drunkFight:
            return 0
        case .gambleFight:
            return 0
        case .observing:
            return 0
        case .prostitution:
            return 200
        case .makingLove:
            return 0
        case .flirt:
            return 0
        case .smithingCraft:
            return 100
        case .alchemyCraft:
            return 70
        case .awareAboutVampire:
            return 0
        case .awareAboutCasualty:
            return 0
        case .findOutCasualty:
            return 0
        case .askForProtection:
            return 400
        case .trade:
            return 0
        case .gameOver:
            return 0
        // standalone actions
        case .cleaning:
            return 0
        case .drinking:
            return 0
        case .eating:
            return 0
        case .lookingAtMirror:
            return 0
        case .suspicioning:
            return 0
        case .learning:
            return 0
        case .reading:
            return 0
        case .praying:
            return 0
        case .tossingCards:
            return 0
        case .workingOnSmithingOrder:
            return 0
        case .workingOnAlchemyPotion:
            return 0
        case .checkingCoins:
            return 0
        case .moans:
            return 0
        case .harvestingFlowers:
            return 0
        case .cleaningWeapon:
            return 0
        case .bathing:
            return 0
        case .vampireMilitaryReport:
            return 0
        default:
            return 0
        }
    }
    
    var icon: String {
        switch self {
        // couple action
        case .conversation:
            return NPCActivityType.socialize.icon
        case .argue:
            return "captions.bubble.fill"
        case .service:
            return NPCActivityType.serve.icon
        case .patrol:
            return NPCActivityType.patrol.icon
        case .drunkFight:
            return "figure.boxing"
        case .gambleFight:
            return "figure.boxing"
        case .observing:
            return "figure.meditation"
        case .prostitution:
            return NPCActivityType.love.icon
        case .makingLove:
            return NPCActivityType.love.icon
        case .flirt:
            return NPCActivityType.flirt.icon
        case .smithingCraft:
            return NPCActivityType.craft.icon
        case .alchemyCraft:
            return NPCActivityType.craft.icon
        case .awareAboutVampire:
            return NPCActivityType.fleeing.icon
        case .awareAboutCasualty:
            return NPCActivityType.casualty.icon
        case .findOutCasualty:
            return NPCActivityType.casualty.icon
        case .askForProtection:
            return NPCActivityType.protect.icon
        case .trade:
            return NPCActivityType.sell.icon
        case .arrest:
            return NPCActivityType.jailed.icon
        case .theft:
            return "hand.raised.fingers.spread"
        case .gameOver:
            return "figure.meditation"
        // standalone actions
        case .cleaning:
            return NPCActivityType.clean.icon
        case .drinking:
            return NPCActivityType.drink.icon
        case .eating:
            return NPCActivityType.eat.icon
        case .lookingAtMirror:
            return "inset.filled.oval.portrait"
        case .suspicioning:
            return NPCActivityType.eat.icon
        case .learning:
            return NPCActivityType.study.icon
        case .reading:
            return NPCActivityType.study.icon
        case .praying:
            return NPCActivityType.pray.icon
        case .tossingCards:
            return NPCActivityType.gamble.icon
        case .workingOnSmithingOrder:
            return NPCActivityType.craft.icon
        case .workingOnAlchemyPotion:
            return NPCActivityType.craft.icon
        case .checkingCoins:
            return "cedisign"
        case .moans:
            return "person.wave.2.fill"
        case .harvestingFlowers:
            return NPCActivityType.harvest.icon
        case .cleaningWeapon:
            return "figure.fencing"
        case .bathing:
            return NPCActivityType.bathe.icon
        case .vampireMilitaryReport:
            return NPCActivityType.fleeing.icon
        }
    }
    
    
    var color: Color {
        switch self {
        // couple action
        case .conversation:
            return NPCActivityType.socialize.color
        case .argue:
            return Color.orange
        case .service:
            return NPCActivityType.serve.color
        case .patrol:
            return NPCActivityType.patrol.color
        case .drunkFight:
            return NPCActivityType.drink.color
        case .gambleFight:
            return NPCActivityType.gamble.color
        case .observing:
            return Color.green
        case .prostitution:
            return NPCActivityType.love.color
        case .makingLove:
            return NPCActivityType.love.color
        case .flirt:
            return NPCActivityType.flirt.color
        case .smithingCraft:
            return NPCActivityType.craft.color
        case .alchemyCraft:
            return NPCActivityType.craft.color
        case .awareAboutVampire:
            return NPCActivityType.fleeing.color
        case .awareAboutCasualty:
            return NPCActivityType.casualty.color
        case .findOutCasualty:
            return NPCActivityType.casualty.color
        case .askForProtection:
            return NPCActivityType.protect.color
        case .trade:
            return NPCActivityType.sell.color
        case .arrest:
            return NPCActivityType.jailed.color
        case .theft:
            return Color.red
        case .gameOver:
            return Theme.bloodProgressColor
        // standalone actions
        case .cleaning:
            return NPCActivityType.clean.color
        case .drinking:
            return NPCActivityType.drink.color
        case .eating:
            return NPCActivityType.eat.color
        case .lookingAtMirror:
            return Color.purple
        case .suspicioning:
            return Theme.awarenessProgressColor
        case .learning:
            return NPCActivityType.study.color
        case .reading:
            return NPCActivityType.study.color
        case .praying:
            return NPCActivityType.pray.color
        case .tossingCards:
            return NPCActivityType.gamble.color
        case .workingOnSmithingOrder:
            return NPCActivityType.craft.color
        case .workingOnAlchemyPotion:
            return Color.green
        case .checkingCoins:
            return Color.yellow
        case .moans:
            return Color.red
        case .harvestingFlowers:
            return NPCActivityType.harvest.color
        case .cleaningWeapon:
            return Color.red
        case .bathing:
            return NPCActivityType.bathe.color
        case .vampireMilitaryReport:
            return Theme.awarenessProgressColor
        }
    }
    
    static func getPossibleStandaloneInteraction(currentNPC: NPC, gameTimeService: GameTimeService, currentScene: Scene) -> NPCInteraction {
        var result = NPCInteraction.observing
        
        var availableInteractions: [NPCInteraction] = []
        /*
         case moans = "moans"
         */
        
        if currentNPC.currentActivity == .clean {
            availableInteractions.append(.cleaning)
        }
        
        if currentNPC.currentActivity == .drink {
            availableInteractions.append(.drinking)
        }
        
        if currentNPC.currentActivity == .eat {
            availableInteractions.append(.eating)
        }
        
        if currentNPC.currentActivity == .study {
            availableInteractions.append(.learning)
            availableInteractions.append(.reading)
        }
        
        if currentNPC.currentActivity == .pray {
            availableInteractions.append(.praying)
        }
        
        if currentNPC.currentActivity == .gamble {
            availableInteractions.append(.tossingCards)
        }
        
        if currentNPC.currentActivity == .craft {
            if currentNPC.profession == .blacksmith && currentScene.sceneType == .blacksmith {
                availableInteractions.append(.workingOnSmithingOrder)
            } else if currentNPC.profession == .alchemist && currentScene.sceneType == .alchemistShop {
                availableInteractions.append(.workingOnAlchemyPotion)
            }
        }
        
        if currentScene.sceneType == .brothel || currentScene.sceneType == .tavern {
            if currentNPC.sex == .female || currentNPC.profession == .courtesan {
                availableInteractions.append(.lookingAtMirror)
            }
        }
        
        if VampireNatureRevealService.shared.getAwareness() > 40 {
            availableInteractions.append(.suspicioning)
        }
        
        if currentNPC.coins.value > 1000 {
            availableInteractions.append(.checkingCoins)
        }
        
        if currentNPC.currentActivity == .harvest && !currentScene.isIndoor {
            availableInteractions.append(.harvestingFlowers)
        }
        
        if currentNPC.isMilitary || currentNPC.profession == .mercenary {
            availableInteractions.append(.cleaningWeapon)
        }
        
        if currentNPC.currentActivity == .bathe {
            availableInteractions.append(.bathing)
        }
        
        result = availableInteractions.randomElement() ?? .observing
        
        return result
    }
    
    static func getPossibleInteraction(currentNPC: NPC, otherNPC: NPC, gameTimeService: GameTimeService, currentScene: Scene) -> NPCInteraction {
        var result = NPCInteraction.observing
        
        var availableInteractions: [NPCInteraction] = []
        
        if otherNPC.isAlive && !currentNPC.isCasualtyWitness && !currentNPC.isCrimeWitness {
            // Vampire awareness
            if currentNPC.currentActivity == .fleeing && currentNPC.isVampireAttackWitness && !otherNPC.isVampireAttackWitness {
                return .awareAboutVampire
            }
            
            // Vampire militaryReport
            if currentNPC.currentActivity == .fleeing && currentNPC.isVampireAttackWitness && !otherNPC.isVampireAttackWitness && otherNPC.isMilitary {
                return .awareAboutVampire
            }
            
            
            // Drunk Fight
            if currentNPC.currentActivity == .drink || currentNPC.currentActivity == .gamble && (!currentNPC.isMilitary && !otherNPC.isMilitary) ||
                (currentNPC.isMilitary && otherNPC.isMilitary){
                let wouldFight = Int.random(in: 0...100) > 95
                
                if wouldFight {
                    availableInteractions.append(Int.random(in: 0...1) > 0 ? .drunkFight : .gambleFight)
                }
            }
            
            // Serve
            if (currentNPC.profession == .tavernKeeper || currentNPC.profession == .servant || currentNPC.profession == .barmaid) && (otherNPC.profession != .tavernKeeper && otherNPC.profession != .servant && otherNPC.profession != .barmaid && otherNPC.profession != .kitchenStaff)
                && (otherNPC.currentActivity == .drink || otherNPC.currentActivity == .eat) {
                
                if otherNPC.coins.couldRemove(NPCInteraction.service.interactionBaseCost) {
                    let wouldOfferService = Int.random(in: 0...100) > 30
                    
                    if wouldOfferService {
                        CoinsManagementService.shared.moveCoins(from: otherNPC, to: currentNPC, amount: NPCInteraction.service.interactionBaseCost)
                        availableInteractions.append(.service)
                    }
                }
            }
            
            // Patrol
            if currentNPC.isMilitary && !otherNPC.isMilitary && otherNPC.profession != .lordLady && !otherNPC.isMilitary {
                if currentNPC.currentActivity == .patrol || currentNPC.currentActivity == .guardPost {
                    let wouldInteract = Int.random(in: 0...100) > (gameTimeService.isNightTime ? 40 : 70)
                    
                    if wouldInteract {
                        availableInteractions.append(.patrol)
                    }
                }
            }
            
            // Prostitution
            if currentNPC.profession == .courtesan && otherNPC.profession != .courtesan && otherNPC.profession != .tavernKeeper {
                var entertainCap = gameTimeService.isNightTime ? 40 : 90
                let locationMatch = currentScene.sceneType == .tavern || currentScene.sceneType == .brothel || currentScene.isIndoor == false
                
                if locationMatch {
                    entertainCap -= 30
                }
          
                if otherNPC.coins.couldRemove(NPCInteraction.prostitution.interactionBaseCost) {
                    let wouldEntertain = Int.random(in: 0...100) > entertainCap
                    
                    if wouldEntertain {
                        CoinsManagementService.shared.moveCoins(from: otherNPC, to: currentNPC, amount: NPCInteraction.prostitution.interactionBaseCost)
                        availableInteractions.append(.prostitution)
                    }
                }
            }
            
            // MakingLove
            if currentNPC.sex != otherNPC.sex && currentNPC.currentActivity == otherNPC.currentActivity {
                if currentNPC.getNPCRelationshipValue(of: otherNPC) > 20 {
                    if (abs(currentNPC.age - otherNPC.age) < 10) && (currentNPC.age + otherNPC.age < 100) {
                        var valueCap = gameTimeService.isNightTime ? 40 : 90
                        let locationMatch = currentScene.sceneType == .house || currentScene.sceneType == .tavern || currentScene.sceneType == .brothel || currentScene.sceneType == .bathhouse
                        
                        if locationMatch {
                            valueCap -= 30
                        }
                  
                        let wouldMakeLove = Int.random(in: 0...100) > valueCap
                            
                        if wouldMakeLove {
                            availableInteractions.append(.makingLove)
                        }
                    }
                }
            }
            
            // Flirt
            if currentNPC.profession != .priest && otherNPC.profession != .priest && currentNPC.sex != otherNPC.sex && currentNPC.age < 50 && otherNPC.age < 50 {
                let entertainCap = gameTimeService.isNightTime ? 70 : 90
          
                let wouldFlirt = Int.random(in: 0...100) > entertainCap
                
                if wouldFlirt {
                    availableInteractions.append(.flirt)
                }
            }
            
            // Smithing
            if currentNPC.profession == .blacksmith && otherNPC.profession != .blacksmith && otherNPC.profession != .apprentice {
                if currentScene.sceneType == .blacksmith && !gameTimeService.isNightTime {
                    
                    let itemToTrade = currentNPC.items.first(where: { $0.type == .armor || $0.type == .weapon })
                    
                    if itemToTrade != nil {
                        if otherNPC.coins.couldRemove(NPCInteraction.smithingCraft.interactionBaseCost + itemToTrade!.cost) {
                            let wouldExecuteOrder = Int.random(in: 0...100) > 30
            
                            if wouldExecuteOrder {
                                CoinsManagementService.shared.moveCoins(from: otherNPC, to: currentNPC, amount: NPCInteraction.smithingCraft.interactionBaseCost + itemToTrade!.cost)
                                ItemsManagementService.shared.moveItem(item: itemToTrade!, from: currentNPC, to: otherNPC)
                                availableInteractions.append(.smithingCraft)
                            }
                        }
                    }
                }
            }
            
            // Alchemy
            if currentNPC.profession == .alchemist && otherNPC.profession != .alchemist && otherNPC.profession != .apprentice {
                if currentScene.sceneType == .alchemistShop && !gameTimeService.isNightTime {
                    
                    let itemToTrade = currentNPC.items.first(where: { $0.type == .alchemy || $0.type == .drink })
                    
                    if itemToTrade != nil {
                        if otherNPC.coins.couldRemove(NPCInteraction.alchemyCraft.interactionBaseCost + itemToTrade!.cost) {
                            let wouldExecuteOrder = Int.random(in: 0...100) > 30
                            
                            if wouldExecuteOrder {
                                CoinsManagementService.shared.moveCoins(from: otherNPC, to: currentNPC, amount: NPCInteraction.alchemyCraft.interactionBaseCost + itemToTrade!.cost)
                                ItemsManagementService.shared.moveItem(item: itemToTrade!, from: currentNPC, to: otherNPC)
                                availableInteractions.append(.alchemyCraft)
                            }
                        }
                    }
                }
            }
            
            // Conversation
            if (currentNPC.currentActivity == otherNPC.currentActivity  ){
                let wouldConversate = Int.random(in: 0...100) >= 20
                
                if wouldConversate {
                    let currentRelationship = currentNPC.getNPCRelationshipValue(of: otherNPC)
                    let argueCap = currentRelationship > 0 ? 98 : 92
                    
                    let wouldArgue = Int.random(in: 0...100) > Int(argueCap)
                    
                    availableInteractions.append(wouldArgue ? .argue : .conversation)
                }
            }
            
            // Looking for protection
            if currentNPC.bloodMeter.currentBlood < 70 && otherNPC.profession == .mercenary && !otherNPC.isNpcInteractionBehaviorSet {
                if currentNPC.coins.couldRemove(NPCInteraction.askForProtection.interactionBaseCost) {
                    let protectionCap = 100 - currentNPC.bloodMeter.currentBlood
                    let wouldAskForProtection = Int.random(in: 0...100) > Int(protectionCap)
                    
                    if wouldAskForProtection {
                        CoinsManagementService.shared.moveCoins(from: currentNPC, to: otherNPC, amount: NPCInteraction.askForProtection.interactionBaseCost)
                        return .askForProtection
                    }
                }
            }
            
            // Trade
            if currentNPC.currentActivity == .sell {
                if (currentScene.sceneType == .blacksmith || currentScene.sceneType == .alchemistShop || currentScene.sceneType == .bookstore
                    || currentNPC.profession == .merchant) && !gameTimeService.isNightTime {
                    
                    let buyer = Int.random(in: 0...1) == 0 ? currentNPC : otherNPC
                    let seller = currentNPC.id == buyer.id ? otherNPC : currentNPC
                    
                    let itemToTrade = seller.items.randomElement()
                    
                    if itemToTrade == nil {
                        if buyer.coins.couldRemove(itemToTrade!.cost) {
                            let wouldTrade = Int.random(in: 0...100) > 70
                            
                            if wouldTrade {
                                CoinsManagementService.shared.moveCoins(from: buyer, to: seller, amount: itemToTrade!.cost)
                                ItemsManagementService.shared.moveItem(item: itemToTrade!, from: seller, to: buyer)
                                availableInteractions.append(.trade)
                            }
                        }
                    }
                }
            }
            
            // Theft
            if currentNPC.profession == .thug && currentNPC.currentActivity == .thieving && !otherNPC.isMilitary && otherNPC.profession != .thug {
                var wouldStealChance = 50
                
                if gameTimeService.isNightTime {
                    wouldStealChance += 25
                }
                
                if otherNPC.currentActivity == .sleep {
                    wouldStealChance += 25
                }
                
                let wouldSteal = Int.random(in: 0...100) < wouldStealChance
                
                if wouldSteal {
                    return .theft
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
