//
//  NPCBehaviorService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 11.04.2025.
//

class NPCBehaviorService: GameService {
    static let shared = NPCBehaviorService()
    private var gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    private var npcInteractionService: NPCInteractionService;

    private var activitiesSet: Int = 0
    
    var activitiesAssigned: [assignedActivity] = []
        
    var npcs: [NPC] = []
        
    init() {
        npcs = NPCReader.getNPCs()
        npcInteractionService = NPCInteractionService()
        DependencyManager.shared.register(npcInteractionService)
    }
        
    func updateActivity() {
        let residentNPCs = npcs.filter { $0.homeLocationId > 0 && $0.isAlive }
        
        // Select non-resident NPCs with specific professions
        let eligibleNonResidentProfessions: [Profession] = [.mercenary, .thug, .pilgrim, .merchant, .alchemist]
        
        let nonResidentNPCs = npcs
            .filter { $0.homeLocationId == 0 && $0.isAlive && eligibleNonResidentProfessions.contains($0.profession) }
            .shuffled()
        
        // Randomly select 30-70 non-resident NPCs
        let nonResidentCount = Int.random(in: 5...20)
        let selectedNonResidentNPCs = Array(nonResidentNPCs.shuffled().prefix(nonResidentCount))
        
        for npc in selectedNonResidentNPCs {
            npc.homeLocationId = 34 // The Long Pier, Docks (Arrivals)
        }
        
        // Combine resident and selected non-resident NPCs
        let npcsToHandle = residentNPCs + selectedNonResidentNPCs
        
        let gameTimeService: GameTimeService = DependencyManager.shared.resolve()

        for npc in npcsToHandle {
            handleNPCBehavior(npc: npc, gameTimeService: gameTimeService)
            //sendSleepToHome(npc: npc)
        }
        
        npcInteractionService.handleNPCInteractionsBehavior()

        for npc in npcsToHandle {
            updateNPCState(npc: npc, gameDay: gameTimeService.currentDay)
        }
    }
    
    struct assignedActivity {
        let isStay: Bool
        let activity: NPCActivityType
        
        init(isStay: Bool, activity: NPCActivityType) {
            self.isStay = isStay
            self.activity = activity
        }
    }
    
    private func handleNPCBehavior(npc: NPC, gameTimeService: GameTimeService) {
        let newActivity = npc.isBeasy || npc.isSpecialBehaviorSet
            ? NPCActivityManager.shared.getSpecialBehaviorActivity(for: npc)
            : NPCActivityManager.shared.getActivity(for: npc)
        
        npc.currentActivity = newActivity
        
        activitiesSet += 1
        
        if newActivity == .sleep {
            sendSleepToHome(npc: npc)
            
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            
            return
        }
        
        let graph = LocationGraph.shared
        
        if let (path, target) = graph.nearestLocation(for: newActivity, from: npc.homeLocationId) {
            if target.id == npc.currentLocationId {
                activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            } else {

                LocationReader.getLocationById(by: npc.currentLocationId)?.removeCharacter(id: npc.id)
                target.addCharacter(npc)
                activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
            }
            
        } else {
            gameEventBusService.addDangerMessage(message: "Cannot find location for activity \(newActivity.rawValue)")
        }
    }
    
    private func logActivitySummary(activityCounts: [NPCActivityType: (staying: Int, moving: Int)]) {
        for (activity, counts) in activityCounts {
            if counts.staying > 0 {
                gameEventBusService.addMessageWithIcon(message: "\(counts.staying) for \(activity.rawValue.capitalized)",  icon: activity.icon, iconColor: activity.color, type: .common)
            }
            if counts.moving > 0 {
                gameEventBusService.addMessageWithIcon(message: "\(counts.moving) for \(activity.rawValue.capitalized)",  icon: activity.icon, iconColor: activity.color, type: .common)
            }
        }
    }

    func sendSleepToHome(npc: NPC) {
        var npcCurrentLocation = LocationReader.getLocationById(by: npc.currentLocationId )
        var npcHomeLocation = LocationReader.getLocationById(by: npc.homeLocationId )
        
        if npcCurrentLocation?.id != npc.homeLocationId {
            npcCurrentLocation?.removeCharacter(id: npc.id)
            
            npcHomeLocation?.addCharacter(npc)
        }
    }
    
    func updateNPCState(npc: NPC, gameDay: Int) {
        if npc.isIntimidated {
            if gameDay > npc.intimidationDay {
                npc.isIntimidated = false
                npc.intimidationDay = 0
            }
        }
        
        if npc.isBeasy {
            npc.isBeasy = false
        }
        
        if npc.isAlive && npc.bloodMeter.currentBlood < 100 {
            npc.bloodMeter.addBlood(2)
        }
    }
    
    
}
