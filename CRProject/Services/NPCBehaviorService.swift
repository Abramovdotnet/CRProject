//
//  NPCBehaviorService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 11.04.2025.
//

class NPCBehaviorService : GameService {
    static let shared = NPCBehaviorService()
    var npcs: [NPC] = []
    
    init () {
        npcs = NPCReader.getNPCs()
    }
    
    func updateActivity() {
        let gameTimeService: GameTimeService = DependencyManager.shared.resolve()
        
        let gameTime = gameTimeService.currentHour
        let dayPhase = gameTimeService.dayPhase
        
        let npc = npcs.first { $0.id == 167}
        if let npc = npc {
            let newActivity = NPCActivityManager.shared.getActivity(for: npc.profession)
            
            DebugLogService.shared.log("Game Time: \(gameTime):00, phase: \(dayPhase). Assigned activity \(newActivity.rawValue.capitalized) to \(npc.name).", category: "NPC")
            
            let graph = LocationGraph.shared

            // Find the nearest suitable location for the NPC's activity
            if let (path, target) = graph.nearestLocation(
                for: newActivity,
                from: npc.homeLocationId,
                time: dayPhase
            ) {
                // Set the NPC at the target location
                target.setCharacters([npc])
                
                DebugLogService.shared.log("\(npc.name) moved to \(target.name) for \(newActivity.rawValue.capitalized)", category: "NPC")
                
                // Log the path taken if needed
                if !path.isEmpty {
                    let pathNames = path.compactMap { graph.locations[$0]?.name }
                    DebugLogService.shared.log("Path taken: \(pathNames.joined(separator: " -> "))", category: "NPC")
                }
            } else {
                DebugLogService.shared.log("No suitable location found for \(npc.name)'s activity: \(newActivity.rawValue.capitalized)", category: "NPC")
            }
        }
    }
}
