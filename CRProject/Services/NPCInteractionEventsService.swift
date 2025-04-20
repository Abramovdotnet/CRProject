//
//  NPCInteractionEventsService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 20.04.2025.
//

class NPCInteractionEventsService : GameService {
    private var gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    private var npcInteractionEvents: [NPCInteractionEvent] = []
    private let maxEvents = 50;
    
    static var shared: NPCInteractionEventsService = DependencyManager.shared.resolve()
    
    func addEvent(_ event: NPCInteractionEvent) {
        npcInteractionEvents.append(event)
        
        if npcInteractionEvents.count > maxEvents {
            npcInteractionEvents.removeFirst()
        }
        
        /*print("Event added: \(event.happenedAtCurrentScene ? "[CURRENT SCENE]" : "") \(event.interactionType.rawValue) between \(event.currentNPC.name) and \(event.otherNPC?.name ?? ""). At \(event.scene.name) on \(event.day). \(event.hour) \(!event.hasSuccess ? "" : event.isSuccess ? "Success" : "Fail")")*/
        
        guard let currentScene = GameStateService.shared.currentScene else { return }
        
        if event.interactionType == .conversation {
            
            if currentScene.id == event.scene.id {
                var randomNotConversationEvent = npcInteractionEvents.filter {
                    $0.scene.id != currentScene.id
                    && !$0.isDiscussed
                    && $0.interactionType != .conversation
                    && $0.interactionType != .service }.randomElement()
                
                guard let randomNotConversationEvent else { return }
                broadCastEventConversationToCurrentScene(currentEvent: event, discussionEvent: randomNotConversationEvent)
            }
        }
    }
    
    func addEvent(interactionType: NPCInteraction, currentNPC: NPC, otherNPC: NPC? = nil, scene: Scene, day: Int, hour: Int, hasSuccess: Bool = false, isSuccess: Bool = false) {
        let event = NPCInteractionEvent(interactionType: interactionType, currentNPC: currentNPC, otherNPC: otherNPC, scene: scene, day: day, hour: hour, hasSuccess: hasSuccess, isSuccess: isSuccess)
        
        addEvent(event)
    }
    
    func getEvents() -> [NPCInteractionEvent] {
        return npcInteractionEvents
    }
    
    func broadCastEventConversationToCurrentScene(currentEvent: NPCInteractionEvent, discussionEvent: NPCInteractionEvent) {
        if let engagedToEventNpc = discussionEvent.otherNPC {
            gameEventBusService.addMessageWithIcon(
                message: "\(currentEvent.currentNPC.name): Humors say that \(discussionEvent.currentNPC.name) \(discussionEvent.interactionType.rawValue) to \(engagedToEventNpc.name), at \(discussionEvent.scene.name). recenlty",
                type: .common
            )
            
            if let commentatorNpc = currentEvent.otherNPC {
                gameEventBusService.addMessageWithIcon(
                    message: "\(commentatorNpc.name): no way!",
                    type: .common
                )
            }
        } else {
            gameEventBusService.addMessageWithIcon(
                message: "\(currentEvent.currentNPC.name): Humors say that \(discussionEvent.currentNPC.name) \(discussionEvent.interactionType.rawValue) at \(discussionEvent.scene.name). recenlty",
                type: .common
            )
            if let commentatorNpc = currentEvent.otherNPC {
                gameEventBusService.addMessageWithIcon(
                    message: "\(commentatorNpc.name): no way!",
                    type: .common
                )
            }
        }
        
        discussionEvent.markAsDiscussed()
    }
}
