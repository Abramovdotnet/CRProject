//
//  NPCInteractionEventsService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 20.04.2025.
//

class NPCInteractionEventsService : GameService {
    
    private var npcInteractionEvents: [NPCInteractionEvent] = []
    private let maxEvents = 50;
    
    static var shared: NPCInteractionEventsService = DependencyManager.shared.resolve()
    
    func addEvent(_ event: NPCInteractionEvent) {
        npcInteractionEvents.append(event)
        
        if npcInteractionEvents.count > maxEvents {
            npcInteractionEvents.removeFirst()
        }
        
        print("Event added: \(event.interactionType.rawValue) between \(event.currentNPC.name) and \(event.otherNPC?.name ?? ""). At \(event.scene.name) on \(event.day). \(event.hour) \(!event.hasSuccess ? "" : event.isSuccess ? "Success" : "Fail")")
    }
    
    func addEvent(interactionType: NPCInteraction, currentNPC: NPC, otherNPC: NPC? = nil, scene: Scene, day: Int, hour: Int, hasSuccess: Bool = false, isSuccess: Bool = false) {
        let event = NPCInteractionEvent(interactionType: interactionType, currentNPC: currentNPC, otherNPC: otherNPC, scene: scene, day: day, hour: hour, hasSuccess: hasSuccess, isSuccess: isSuccess)
        
        addEvent(event)
    }
    
    func getEvents() -> [NPCInteractionEvent] {
        return npcInteractionEvents
    }
}
