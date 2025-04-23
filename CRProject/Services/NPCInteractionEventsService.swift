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
        
        guard let currentScene = GameStateService.shared.currentScene else { return }
        
        let isCurrentScene = currentScene.id == event.scene.id
        
        if isCurrentScene {
            if event.interactionType == .conversation {
                let randomNotConversationEvent = npcInteractionEvents.filter {
                    $0.scene.id != currentScene.id
                    && !$0.isDiscussed
                    && $0.interactionType != .conversation
                    && $0.interactionType != .service }.randomElement()
                
                guard let randomNotConversationEvent else { return }
                broadCastEventConversationToCurrentScene(currentEvent: event, discussionEvent: randomNotConversationEvent)
            } else {
                broadCastCurrentSceneEvent(currentEvent: event)
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
    
    func broadCastCurrentSceneEvent(currentEvent: NPCInteractionEvent) {
        if let engagedToEventNpc = currentEvent.otherNPC {
            gameEventBusService.addMessageWithIcon(
                type: .common,
                location: currentEvent.scene.name,
                primaryNPC: currentEvent.currentNPC,
                secondaryNPC: engagedToEventNpc,
                interactionType: currentEvent.interactionType,
                hasSuccess: currentEvent.hasSuccess,
                isSuccess: currentEvent.isSuccess
            )
        } else {
            if currentEvent.isSignleNpcEvent {
                gameEventBusService.addMessageWithIcon(
                    type: .common,
                    location: currentEvent.scene.name,
                    primaryNPC: currentEvent.currentNPC,
                    secondaryNPC: nil,
                    interactionType: currentEvent.interactionType,
                    hasSuccess: currentEvent.hasSuccess,
                    isSuccess: currentEvent.isSuccess
                )
            }
        }
    }
    
    func broadCastEventConversationToCurrentScene(currentEvent: NPCInteractionEvent, discussionEvent: NPCInteractionEvent) {
        if let engagedToEventNpc = currentEvent.otherNPC {
            if let engagedToDiscussionEvent = discussionEvent.otherNPC {
                gameEventBusService.addMessageWithIcon(
                    type: .common,
                    location: currentEvent.scene.name,
                    primaryNPC: currentEvent.currentNPC,
                    secondaryNPC: engagedToEventNpc,
                    interactionType: NPCInteraction.conversation,
                    hasSuccess: false,
                    isSuccess: nil,
                    isDiscussion: true,
                    messageLocation: discussionEvent.scene.name,
                    rumorInteractionType: discussionEvent.interactionType,
                    rumorPrimaryNPC: discussionEvent.currentNPC,
                    rumorSecondaryNPC: discussionEvent.otherNPC
                )
            }
        } else {
            gameEventBusService.addMessageWithIcon(
                type: .common,
                location: currentEvent.scene.name,
                primaryNPC: currentEvent.currentNPC,
                interactionType: NPCInteraction.conversation,
                hasSuccess: false,
                isSuccess: nil,
                isDiscussion: true,
                messageLocation: discussionEvent.scene.name,
                rumorInteractionType: discussionEvent.interactionType,
                rumorPrimaryNPC: discussionEvent.currentNPC,
                rumorSecondaryNPC: discussionEvent.otherNPC
            )
        }
        
        discussionEvent.markAsDiscussed()
    }
}
