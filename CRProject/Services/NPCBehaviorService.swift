//
//  NPCBehaviorService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 11.04.2025.
//

class NPCBehaviorService: GameService {
    static let shared = NPCBehaviorService()
    private let gameEventBusService: GameEventsBusService
    private let gameTimeService: GameTimeService
    private let locationGraph: LocationGraph
    private let npcInteractionService: NPCInteractionService
    
    private var activitiesSet: Int = 0
    var activitiesAssigned: [assignedActivity] = []
    var npcs: [NPC] = []
    
    // Cache for eligible non-resident professions
    private let eligibleNonResidentProfessions: Set<Profession> = [.mercenary, .thug, .pilgrim, .merchant, .alchemist]
    
    init() {
        self.gameEventBusService = DependencyManager.shared.resolve()
        self.gameTimeService = DependencyManager.shared.resolve()
        self.locationGraph = LocationGraph.shared
        self.npcs = NPCReader.getNPCs()
        self.npcInteractionService = NPCInteractionService()
        DependencyManager.shared.register(npcInteractionService)
    }
    
    func updateActivity() {
        // Use lazy collections to avoid creating intermediate arrays
        let residentNPCs = npcs.lazy.filter { $0.homeLocationId > 0}
        
        let nonResidentNPCs = npcs.lazy
            .filter { $0.homeLocationId == 0 && self.eligibleNonResidentProfessions.contains($0.profession) }
            .shuffled()
        
        let nonResidentCount = Int.random(in: 5...20)
        let selectedNonResidentNPCs = Array(nonResidentNPCs.prefix(nonResidentCount))
        
        // Batch update home locations
        selectedNonResidentNPCs.forEach { $0.homeLocationId = 34 }
        
        let npcsToHandle = residentNPCs + selectedNonResidentNPCs
        
        // Process NPCs in parallel where possible
        npcsToHandle.forEach { npc in
            handleNPCBehavior(npc: npc, gameTimeService: gameTimeService)
        }
        
        npcInteractionService.handleNPCInteractionsBehavior()
        
        npcsToHandle.forEach { npc in
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
        let newActivity = npc.isBeasyByPlayerAction || npc.isSpecialBehaviorSet || npc.isNpcInteractionBehaviorSet
            ? NPCActivityManager.shared.getSpecialBehaviorActivity(for: npc)
            : NPCActivityManager.shared.getActivity(for: npc)
        
        if !npc.isAlive {
            return
        }
        npc.currentActivity = newActivity
        activitiesSet += 1
        
        if newActivity == .sleep {
            sendSleepToHome(npc: npc)
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            return
        }
        
        if newActivity == .protect {
            var target = NPCReader.getRuntimeNPC(by: npc.npcInteractionTargetNpcId)
            
            if target != nil {
                sendAfterNPC(follower: npc, target: target!)
                activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
            }

            return
        }
        
        if newActivity == .meet {
            var friendId = npc.npcsRelationship.first { $0.state == .friend || $0.state == .ally }
            
            if friendId != nil {
                var friend = NPCReader.getRuntimeNPC(by: friendId!.npcId)!
                
                sendAfterNPC(follower: npc, target: friend)
                activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
            }
            
        }
        
        if newActivity == .followingPlayer || newActivity == .allyingPlayer || newActivity == .seductedByPlayer {
            sendAfterPlayer(npc: npc)
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            return
        }
        
        guard let (path, target) = locationGraph.nearestLocation(for: newActivity, from: npc.homeLocationId) else {
            gameEventBusService.addDangerMessage(message: "Cannot find location for activity \(newActivity.rawValue)")
            return
        }
        
        if target.id == npc.currentLocationId {
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
        } else {
            LocationReader.getLocationById(by: npc.currentLocationId)?.removeCharacter(id: npc.id)
            target.addCharacter(npc)
            activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
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
        let npcCurrentLocation = LocationReader.getLocationById(by: npc.currentLocationId)
        let npcHomeLocation = LocationReader.getLocationById(by: npc.homeLocationId)
        
        if npcCurrentLocation?.id != npc.homeLocationId {
            npcCurrentLocation?.removeCharacter(id: npc.id)
            npcHomeLocation?.addCharacter(npc)
        }
    }
    
    func sendAfterNPC(follower: NPC, target: NPC) {
        let followerCurrentLocation = LocationReader.getLocationById(by: follower.currentLocationId)
        let targetCurrentLocation = LocationReader.getLocationById(by: target.currentLocationId)
        
        if followerCurrentLocation?.id != targetCurrentLocation?.id {
            followerCurrentLocation?.removeCharacter(id: follower.id)
            targetCurrentLocation?.addCharacter(follower)
        }
    }
    
    func sendAfterPlayer(npc: NPC) {
        let npcCurrentLocation = LocationReader.getLocationById(by: npc.currentLocationId)
        let playerLocation = GameStateService.shared.currentScene
        
        guard let playerLocationId = playerLocation?.id else { return }
        
        if npc.currentLocationId != playerLocationId {
            npcCurrentLocation?.removeCharacter(id: npc.id)
            playerLocation?.addCharacter(npc)
        }
    }
    
    func updateNPCState(npc: NPC, gameDay: Int) {
        if npc.isIntimidated && gameDay > npc.intimidationDay {
            npc.isIntimidated = false
            npc.intimidationDay = 0
        }
        
        if npc.isBeasyByPlayerAction {
            npc.isBeasyByPlayerAction = false
        }
        
        if npc.specialBehaviorTime > 0 {
            npc.specialBehaviorTime -= 1
        }
        
        if npc.specialBehaviorTime <= 0 {
            npc.isSpecialBehaviorSet = false
        }
        
        if npc.npcInteractionSpecialTime > 0 {
            npc.npcInteractionSpecialTime -= 1
        }
        
        if npc.npcInteractionSpecialTime <= 0 && npc.isNpcInteractionBehaviorSet {
            npc.isNpcInteractionBehaviorSet = false
            npc.npcInteractionTargetNpcId = 0
            
            if npc.alliedWithNPC != nil {
                npc.alliedWithNPC?.alliedWithNPC = nil
                npc.alliedWithNPC = nil
            }
        }
        
        if npc.isAlive && npc.bloodMeter.currentBlood < 100 {
            npc.bloodMeter.addBlood(2)
        }
        
        if !npc.isAlive && npc.isSpecialBehaviorSet {
            npc.isSpecialBehaviorSet = false
            npc.specialBehaviorTime = 0
        }
        
        if !npc.isAlive && npc.isNpcInteractionBehaviorSet {
            npc.isNpcInteractionBehaviorSet = false
            npc.npcInteractionTargetNpcId = 0
            
            if npc.alliedWithNPC != nil {
                npc.alliedWithNPC?.alliedWithNPC = nil
                npc.alliedWithNPC = nil
            }
        }
    }
}
