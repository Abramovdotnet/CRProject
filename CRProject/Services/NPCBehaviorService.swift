//
//  NPCBehaviorService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 11.04.2025.
//

class NPCBehaviorService: GameService {
    static let shared = NPCBehaviorService()
    private var gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    
    private var notAssigned: Int = 0
    private var activitiesSet: Int = 0
    
    var activitiesAssigned: [assignedActivity] = []
        
    var npcs: [NPC] = []
        
    init() {
        npcs = NPCReader.getNPCs()
    }
        
    func updateActivity() {
        let npcsToHandle = npcs.filter { $0.homeLocationId > 0 }

        for npc in npcsToHandle {
            handleNPCBehavior(npc: npc)
        }
        
        // Create a dictionary to count each activity type
        var activityCounts: [NPCActivityType: Int] = [:]
        for activity in activitiesAssigned {
            activityCounts[activity.activity] = (activityCounts[activity.activity] ?? 0) + 1
        }
        
        // Log counts for each activity type with icons
        for (activity, count) in activityCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            gameEventBusService.addMessageWithIcon(
                message: "\(count) \(activity.rawValue.capitalized)",
                icon: activity.icon,
                iconColor: activity.color,
                type: .common
            )
        }
        
        gameEventBusService.addCommonMessage(message: "\(notAssigned) not assigned")
        gameEventBusService.addCommonMessage(message: "\(activitiesSet) activities set")
        
        notAssigned = 0
        activitiesSet = 0
        activitiesAssigned = []
        
        var locations = LocationReader.getLocations()
            .filter( { $0.npcCount() > 0 } )
            .sorted(by: {$0.npcCount() > $1.npcCount() })
            .prefix(5)
        
        var emptyLocs = LocationReader.getLocations()
            .filter( { $0.sceneType != .town && $0.sceneType != .road && $0.sceneType != .district && $0.npcCount() == 0 && $0.sceneType != .house})
        
        for location in locations {
            gameEventBusService.addCommonMessage(message: "\(location.name) characters: \(location.npcCount())")
            DebugLogService.shared.log("\(location.name) characters: \(location.npcCount())")
        }
        
        for location in emptyLocs {
            gameEventBusService.addCommonMessage(message: "\(location.name), Type: \(location.sceneType.rawValue) is empty")
            DebugLogService.shared.log("\(location.name), Type: \(location.sceneType.rawValue) is empty")
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
    
    private func handleNPCBehavior(npc: NPC) {
        let gameTimeService: GameTimeService = DependencyManager.shared.resolve()
        let newActivity = npc.isBeasy
            ? NPCActivityManager.shared.getActionActivity(for: npc)
            : NPCActivityManager.shared.getActivity(for: npc)
        
        npc.currentActivity = newActivity
        
        activitiesSet += 1
        
        print("\(newActivity.rawValue) set for \(npc.name): \(npc.profession.rawValue)")
        
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
            
            updateNPCState(npc: npc, gameDay: gameTimeService.currentDay)
        } else {
            gameEventBusService.addDangerMessage(message: "Cannot find location for activity \(newActivity.rawValue)")
            notAssigned += 1
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
            
            if npcHomeLocation == npcHomeLocation {
                npcHomeLocation?.addCharacter(npc)
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
        
        if npc.isAlive && npc.bloodMeter.currentBlood < 100 {
            npc.bloodMeter.addBlood(2)
        }
    }
}
