//
//  NPCBehaviorService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 11.04.2025.
//

class NPCBehaviorService : GameService {
    static let shared = NPCBehaviorService()
    private var gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    var npcs: [NPC] = []
    
    init () {
        npcs = NPCReader.getNPCs()
    }
    
    func updateActivity() {
        let npcsToHandle = npcs.filter( { $0.homeLocationId > 0 } )
        
        for npc in npcsToHandle {
            handleNPCBehavior(npc: npc)
        }
    }
    
    func handleNPCBehavior(npc: NPC) {
        let gameTimeService: GameTimeService = DependencyManager.shared.resolve()
        
        let gameTime = gameTimeService.currentHour
        let gameDay = gameTimeService.currentDay
        let dayPhase = gameTimeService.dayPhase
        
        let newActivity = npc.isBeasy
            ? NPCActivityManager.shared.getActionActivity(for: npc)
            : NPCActivityManager.shared.getActivity(for: npc)
        
        npc.currentActivity = newActivity
        
        if newActivity == .sleep {
            sendSleepToHome(npc: npc)
            return
        }
        
        DebugLogService.shared.log("Game Time: \(gameTime):00, phase: \(dayPhase). Assigned activity \(newActivity.rawValue.capitalized) to \(npc.name).", category: "NPC")
        
        let graph = LocationGraph.shared

        // Find the nearest suitable location for the NPC's activity
        if let (path, target) = graph.nearestLocation(
            for: newActivity,
            from: npc.homeLocationId
        ) {
            if target.id == npc.currentLocationId {
                gameEventBusService.addMessageWithIcon(message: "\(npc.name) staying at \(target.name) for \(newActivity.rawValue.capitalized)" , icon: newActivity.icon, iconColor: newActivity.color, type: .common)
                DebugLogService.shared.log("\(npc.name) staying at \(target.name) for \(newActivity.rawValue.capitalized)", category: "NPC Behavior")
           
            } else {
                var npcCurrentLocation = LocationReader.getLocationById(by: npc.currentLocationId )
                
                // Remove NPC from it's current location
                if let npcCurrentLocation = npcCurrentLocation {
                    npcCurrentLocation.removeCharacter(id: npc.id)
                }
                // Set the NPC at the target location
                target.addCharacter(npc)
                
                gameEventBusService.addMessageWithIcon(message: "\(npc.name) moved to \(target.name) for \(newActivity.rawValue.capitalized)", icon: newActivity.icon, iconColor: newActivity.color, type: .common)
                DebugLogService.shared.log("\(npc.name) moved to \(target.name) for \(newActivity.rawValue.capitalized)", category: "NPC Behavior")
                
                // Log the path taken if needed
                if !path.isEmpty {
                    let pathNames = path.compactMap { graph.locations[$0]?.name }
                    DebugLogService.shared.log("Path taken: \(pathNames.joined(separator: " -> "))", category: "NPC")
                }
            }
            
            updateNPCState(npc: npc, gameDay: gameDay)
        } else {
            DebugLogService.shared.log("No suitable location found for \(npc.name)'s activity: \(newActivity.rawValue.capitalized)", category: "ERROR")
            gameEventBusService.addMessageWithIcon(message: "No suitable location found for \(npc.name)'s activity: \(newActivity.rawValue.capitalized)", icon: newActivity.icon, iconColor: newActivity.color, type: .danger)
        }
    }
    
    func sendSleepToHome(npc: NPC) {
        var npcCurrentLocation = LocationReader.getLocationById(by: npc.currentLocationId )
        var npcHomeLocation = LocationReader.getLocationById(by: npc.homeLocationId )
        
        if npcCurrentLocation?.id != npc.homeLocationId {
            npcCurrentLocation?.removeCharacter(id: npc.id)
            
            if npcHomeLocation == npcHomeLocation {
                npcHomeLocation?.addCharacter(npc)
                
                if let homeLocationName = npcHomeLocation?.name as? String {
                    gameEventBusService.addMessageWithIcon(message: "\(npc.name) moved to \(homeLocationName) for Sleep",  icon: NPCActivityType.sleep.icon, iconColor: NPCActivityType.sleep.color, type: .common)
                }
            }
        } else {
            if let homeLocationName = npcHomeLocation?.name as? String {
                gameEventBusService.addMessageWithIcon(message: "\(npc.name) staying at  \(homeLocationName) for Sleep",  icon: NPCActivityType.sleep.icon, iconColor: NPCActivityType.sleep.color, type: .common)
            }
        }
    }
    
    func updateNPCState(npc: NPC, gameDay: Int) {
        if npc.isIntimidated {
            if gameDay > npc.intimidationDay {
                npc.isIntimidated = false
            }
        }
        
        if npc.isBeasy && npc.currentActivity != .fleeing {
            npc.isBeasy = false
        }
        
        if npc.isAlive && !npc.isBeasy && npc.bloodMeter.currentBlood < 100 {
            npc.bloodMeter.addBlood(2)
        }
    }
}
