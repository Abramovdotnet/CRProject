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
        let allScenes = LocationReader.getLocations()
        self.locationGraph = LocationGraph(scenes: allScenes)
        self.npcs = NPCReader.getNPCs()
        self.npcInteractionService = NPCInteractionService()
        DependencyManager.shared.register(npcInteractionService)
    }
    
    func updateNPCsActivities() {
        // Use lazy collections to avoid creating intermediate arrays
        let residentNPCs = npcs.lazy.filter { $0.homeLocationId > 0}
        
        let npcsToHandle = residentNPCs
        
        // Process NPCs in parallel where possible
        npcsToHandle.forEach { npc in
            handleNPCMovementBehavior(npc: npc, gameTimeService: gameTimeService)
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
    
    private func handleNPCMovementBehavior(npc: NPC, gameTimeService: GameTimeService) {
        let newActivity = npc.isBeasyByPlayerAction || npc.isSpecialBehaviorSet || npc.isNpcInteractionBehaviorSet
            ? NPCActivityManager.shared.getSpecialBehaviorActivity(for: npc)
            : NPCActivityManager.shared.getActivity(for: npc)
        
        if !npc.isAlive {
            if npc.deathStatus == .confirmed {
                sendToCemetery(npc: npc)
                return
            }
            return
        }
        npc.currentActivity = newActivity
        activitiesSet += 1
        
        if newActivity == .sleep {
            sendSleepToHome(npc: npc)
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            return
        }
        
        if newActivity == .protect || newActivity == .patrol || newActivity == .pray {
            let targetNpcId = npc.npcInteractionTargetNpcId
            if targetNpcId > 0,
               let target = NPCReader.getRuntimeNPC(by: targetNpcId) {
                sendAfterNPC(follower: npc, target: target)
                activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
                if newActivity == .pray || newActivity == .protect || newActivity == .patrol {
                     return
                }
            } else if newActivity == .protect || newActivity == .patrol {
                activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
                return
            }
        }
        
        if newActivity == .meet {
            let friendId = npc.npcsRelationship.first { $0.state == .friend || $0.state == .ally }
            
            if friendId != nil {
                let friend = NPCReader.getRuntimeNPC(by: friendId!.npcId)!
                
                sendAfterNPC(follower: npc, target: friend)
                activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
                return
            }
        }
        
        if newActivity == .followingPlayer || newActivity == .allyingPlayer || newActivity == .seductedByPlayer {
            sendAfterPlayer(npc: npc)
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            return
        }
        
        let allScenes = LocationReader.getLocations()
        
        let validSceneTypeStrings = newActivity.getValidLocations(for: npc.profession)
        
        if validSceneTypeStrings.isEmpty && newActivity != .idle && newActivity != .travel {
            DebugLogService.shared.log("NPC \(npc.name) activity \(newActivity.rawValue) has no valid location types defined. NPC stays.", category: "NPCBehavior")
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            return
        }

        let targetSceneTypes = validSceneTypeStrings.compactMap { SceneType(rawValue: $0) ?? SceneType(rawValue: $0.lowercased()) ?? SceneType(rawValue: $0.capitalized) }

        var candidateScenes: [Scene] = []
        if newActivity == .idle || newActivity == .travel {
            if validSceneTypeStrings.isEmpty {
                 activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
                 return
            }
             candidateScenes = allScenes.filter { scene in targetSceneTypes.contains(scene.sceneType) }
        } else {
            candidateScenes = allScenes.filter { scene in targetSceneTypes.contains(scene.sceneType) }
        }

        if candidateScenes.isEmpty {
            DebugLogService.shared.log("NPC \(npc.name) activity \(newActivity.rawValue): No candidate scenes found for types [\(validSceneTypeStrings.joined(separator: ", "))]. NPC stays.", category: "NPCBehavior")
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            return
        }
        
        var shortestPathLength = Int.max
        var bestTargetScene: Scene? = nil
        
        if let currentNpcScene = allScenes.first(where: { $0.id == npc.currentLocationId }),
           candidateScenes.contains(where: { $0.id == currentNpcScene.id }) {
        }

        for candidateScene in candidateScenes {
            if candidateScene.id == npc.currentLocationId {
                if bestTargetScene == nil || 0 < shortestPathLength {
                    shortestPathLength = 0
                    bestTargetScene = candidateScene
                }
                continue
            }

            if let path = locationGraph.findShortestPath(from: npc.currentLocationId, to: candidateScene.id) {
                if !path.isEmpty {
                    let currentPathCost = path.count 
                    if currentPathCost < shortestPathLength {
                        shortestPathLength = currentPathCost
                        bestTargetScene = candidateScene
                    }
                }
            }
        }

        if let targetScene = bestTargetScene {
            if targetScene.id == npc.currentLocationId {
                activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
            } else {
                do {
                    if npc.currentLocationId > 0 {
                        if let currentSceneObject = allScenes.first(where: { $0.id == npc.currentLocationId }) {
                             currentSceneObject.removeCharacter(id: npc.id)
                        } else if let currentSceneRuntime = try? LocationReader.getRuntimeLocation(by: npc.currentLocationId) {
                            currentSceneRuntime.removeCharacter(id: npc.id)
                        } else {
                             DebugLogService.shared.log("Could not find current scene object for ID \(npc.currentLocationId) to remove NPC \(npc.name).", category: "NPCBehavior")
                        }
                    }
                    let runtimeTargetScene = try LocationReader.getRuntimeLocation(by: targetScene.id)
                    runtimeTargetScene.addCharacter(npc)
                    activitiesAssigned.append(assignedActivity(isStay: false, activity: newActivity))
                    DebugLogService.shared.log("NPC \(npc.name) moving to \(targetScene.name) for activity \(newActivity.rawValue). Path length: \(shortestPathLength)", category: "NPCBehavior")

                } catch {
                    DebugLogService.shared.log("Failed to move NPC \(npc.name) to \(targetScene.name): \(error.localizedDescription)", category: "NPCBehavior")
                    activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
                }
            }
        } else {
            DebugLogService.shared.log("NPC \(npc.name) activity \(newActivity.rawValue): No suitable target scene found or path to them. NPC stays.", category: "NPCBehavior")
            activitiesAssigned.append(assignedActivity(isStay: true, activity: newActivity))
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
    
    private func sendToCemetery(npc: NPC) {
        // Find all cemetery locations
        let cemeteryLocations = LocationReader.getLocations().filter { $0.sceneType == .cemetery }
        
        // If no cemetery found, return
        if cemeteryLocations.isEmpty {
            gameEventBusService.addDangerMessage(message: "No cemetery found for burying \(npc.name)")
            return
        }
        
        // Get a random cemetery
        let randomCemetery = cemeteryLocations.randomElement()!
        
        // Remove NPC from current location and move to cemetery
        do {
            let npcCurrentLocation = try LocationReader.getRuntimeLocation(by: npc.currentLocationId)
            npcCurrentLocation.removeCharacter(id: npc.id)
            randomCemetery.addCharacter(npc)
            
            // Update NPC death status to buried
            npc.deathStatus = .buried
            
            gameEventBusService.addMessageWithIcon(
                message: "\(npc.name) has been buried in \(randomCemetery.name)",
                icon: "cross.fill",
                iconColor: .gray,
                type: .common
            )
            
            PopUpState.shared.show(title: "Burial", details: "\(npc.name) sent on his final journey. Date: Day \(GameTimeService.shared.currentDay) at \(GameTimeService.shared.currentHour):00", image: .asset(name: "graveIcon"))
        } catch {
            gameEventBusService.addDangerMessage(message: "Failed to move \(npc.name) to cemetery: \(error.localizedDescription)")
        }
    }
}
