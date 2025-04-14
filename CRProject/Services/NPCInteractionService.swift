//
//  NPCInteractionService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 13.04.2025.
//

class NPCInteractionService : GameService {
    private let gameEventBusService: GameEventsBusService
    private let gameTimeService: GameTimeService
    
    init() {
        self.gameEventBusService = DependencyManager.shared.resolve()
        self.gameTimeService = DependencyManager.shared.resolve()
    }
    
    func handleNPCInteractionsBehavior() {
        var scenes = LocationReader.getLocations()
            .filter { $0.npcCount() > 1 }  // Only filter out completely empty scenes
        
        for scene in scenes {
            var npcs = scene.getNPCs()
            
            // Process each NPC in the scene
            for npc in npcs {
                // Reset interaction if needed
                if npc.currentInteractionNPC != nil {
                    npc.currentInteractionNPC = nil
                    continue
                }
                
                // Skip dead NPCs
                if npc.isAlive == false {
                    continue
                }
                
                if npc.isCasualtyWitness {
                    print("WITNESS")
                }
                
                // Skip sleeping NPCs
                guard npc.currentActivity != .sleep else { continue }
                
                // Find potential interaction targets
                var potentialTargets = npcs.filter { otherNPC in
                    otherNPC.id != npc.id &&
                    otherNPC.currentInteractionNPC == nil &&
                    isInteractionPossible(currentNPC: npc, otherNPC: otherNPC)
                }
                
                // Prioritize casualty discovery
                var target = potentialTargets.first(where: { !$0.isAlive })
                
                
                if npc.isCasualtyWitness {
                    print(">>> Current NPC is a casualty witness: \(npc.name)")
                }
                if target != nil {
                    print(">>> Found casualty: \(target!.name)")
                }
                
                if target == nil {
                    // Try to find an interaction target
                    target = potentialTargets.randomElement()
                }
                
                if target != nil {
                    // Set up the interaction
                    npc.currentInteractionNPC = target
                    target?.currentInteractionNPC = npc
                    
                    // Trigger the interaction event
                    triggerInteractionEvent(scene: scene, currentNPC: npc, otherNPC: target!)
                }
            }
        }
    }
    
    private func isInteractionPossible(currentNPC: NPC, otherNPC: NPC) -> Bool {
        return currentNPC.isAlive &&
        currentNPC.currentActivity != .sleep && otherNPC.currentActivity != .sleep &&
        // Allow fleeing NPCs to interact with non-fleeing NPCs
        otherNPC.currentActivity != .fleeing
    }
    
    private func triggerInteractionEvent(scene: Scene, currentNPC: NPC, otherNPC: NPC) {
        var interaction = NPCInteraction.getPossibleInteraction(currentNPC: currentNPC, otherNPC: otherNPC, gameTimeService: gameTimeService, currentScene: scene)
        
        if interaction != .observing {
            switch interaction {
            case .conversation:
                break
            case .service:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) serving \(otherNPC.name),  \(otherNPC.profession.rawValue) at \(scene.name.capitalized)",  icon: NPCActivityType.serve.icon, iconColor: NPCActivityType.serve.color, type: .common)
            case .patrol:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) stops \(otherNPC.name),  \(otherNPC.profession.rawValue) at \(scene.name.capitalized)",  icon: NPCActivityType.patrol.icon, iconColor: NPCActivityType.patrol.color, type: .common)
            case .drunkFight:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) starts to fights with \(otherNPC.name), \(otherNPC.profession.rawValue) after warm dispute at \(scene.name.capitalized)",  icon: NPCActivityType.drink.icon, iconColor: NPCActivityType.drink.color, type: .common)
            case .gambleFight:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) starts to fights with \(otherNPC.name), \(otherNPC.profession.rawValue) after warm dispute at \(scene.name.capitalized)",  icon: NPCActivityType.drink.icon, iconColor: NPCActivityType.drink.color, type: .common)
            case .prostitution:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) and \(otherNPC.name),  \(otherNPC.profession.rawValue) have a good time at \(scene.name.capitalized)",  icon: NPCActivityType.love.icon, iconColor: NPCActivityType.love.color, type: .common)
            case .flirt:
                var isSuccesful = Int.random(in: 0...100) > 80
                
                if isSuccesful {
                    gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) flirt with \(otherNPC.name),  \(otherNPC.profession.rawValue) at \(scene.name.capitalized)",  icon: NPCActivityType.flirt.icon, iconColor: NPCActivityType.flirt.color, type: .common)
                } else {
                    gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) tries to flirts with \(otherNPC.name), \(otherNPC.profession.rawValue) at \(scene.name.capitalized), but beeing rejected",  icon: "heart.slash", iconColor: NPCActivityType.flirt.color, type: .common)
                }
            case .smithingCraft:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) completed smithing order for \(otherNPC.name),  \(otherNPC.profession.rawValue) at \(scene.name.capitalized)",  icon: NPCActivityType.craft.icon, iconColor: NPCActivityType.craft.color, type: .common)
            case .alchemyCraft:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) completed alchemy order for \(otherNPC.name),  \(otherNPC.profession.rawValue) at \(scene.name.capitalized)",  icon: NPCActivityType.craft.icon, iconColor: NPCActivityType.craft.color, type: .common)
            case .awareAboutVampire:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) warns \(otherNPC.name),  \(otherNPC.profession.rawValue) about vampire attack, \(scene.name.capitalized)",  icon: NPCActivityType.fleeing.icon, iconColor: NPCActivityType.fleeing.color, type: .common)
            case .findOutCasualty:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) just found dead corpse of \(otherNPC.name),  \(otherNPC.profession.rawValue), at \(scene.name.capitalized)",  icon: NPCActivityType.casualty.icon, iconColor: NPCActivityType.casualty.color, type: .common)
            case .awareAboutCasualty:
                gameEventBusService.addMessageWithIcon(message: "\(currentNPC.name), \(currentNPC.profession.rawValue) reports \(otherNPC.name),  \(otherNPC.profession.rawValue) about casualty, \(scene.name.capitalized)",  icon: NPCActivityType.casualty.icon, iconColor: NPCActivityType.casualty.color, type: .common)
            case .gameOver:
                VampireNatureRevealService.shared.increaseAwareness(for: scene.id, amount: 100.0)
            case .observing:
                return
            }
        }
        
        if interaction == .drunkFight || interaction == .gambleFight {
            var currentNPCHasAdvantage = (currentNPC.profession == .guardman || currentNPC.profession == .cityGuard) &&
                (otherNPC.profession != .guardman || otherNPC.profession == .cityGuard)
            var successCap = currentNPCHasAdvantage ? 70 : 100
            var currentNPCWon = Int.random(in: 0...100) > successCap
            
            if currentNPCWon {
                currentNPC.bloodMeter.useBlood(Float.random(in: 10.0...30.0))
                otherNPC.bloodMeter.useBlood(Float.random(in: 30.0...50.0))
            } else {
                currentNPC.bloodMeter.useBlood(Float.random(in: 20.0...50.0))
                otherNPC.bloodMeter.useBlood(Float.random(in: 20.0...50.0))
            }
        } else if interaction == .awareAboutVampire {
            otherNPC.currentActivity = .fleeing
            otherNPC.isVampireAttackWitness = true
        } else if interaction == .findOutCasualty {
            currentNPC.isCasualtyWitness = true
            currentNPC.isSpecialBehaviorSet = true
            currentNPC.casualtyNpcId = otherNPC.id
            otherNPC.deathStatus = .investigated
        } else if interaction == .awareAboutCasualty {
            currentNPC.isCasualtyWitness = false
            currentNPC.isSpecialBehaviorSet = false
            
            var casualtyNPC = NPCReader.getRuntimeNPC(by: currentNPC.casualtyNpcId )
            
            if casualtyNPC != nil {
                casualtyNPC?.deathStatus = .confirmed
                currentNPC.casualtyNpcId = 0
            }
        }
    }
}

enum NPCInteraction : String, CaseIterable, Codable {
    case conversation = "conversation"
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
            if (currentNPC.profession == .tavernKeeper || currentNPC.profession == .servant || currentNPC.profession == .barmaid) && (otherNPC.profession != .tavernKeeper && otherNPC.profession != .servant && otherNPC.profession != .barmaid && otherNPC.profession != .kitchenStaff) {
                var wouldOfferService = Int.random(in: 0...100) > 20
                
                availableInteractions.append(wouldOfferService ? .service : .observing)
            }
            
            // Patrol
            if currentNPC.isMilitary && !otherNPC.isMilitary && otherNPC.profession != .lordLady {
                if currentNPC.currentActivity == .patrol || currentNPC.currentActivity == .guardPost {
                    if otherNPC.currentActivity == .drink || otherNPC.currentActivity == .love  || otherNPC.currentActivity == .spy {
                        var wouldInteract = Int.random(in: 0...100) > 70
                        
                        if wouldInteract {
                            availableInteractions.append(.patrol)
                        }
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

            } else {
                var wouldConversate = Int.random(in: 0...100) > 20
                
                if wouldConversate {
                    availableInteractions.append(.conversation)
                }
            }
            
            // Flirt
            if currentNPC.profession != .priest && otherNPC.profession != .priest && currentNPC.sex != otherNPC.sex && currentNPC.age < 50 && otherNPC.age < 50 {
                var entertainCap = gameTimeService.isNightTime ? 85 : 90
          
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
