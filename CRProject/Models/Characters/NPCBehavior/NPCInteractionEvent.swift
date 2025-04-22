//
//  NPCInteractionEvent.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 20.04.2025.
//

class NPCInteractionEvent {
    var interactionType: NPCInteraction
    var currentNPC: NPC
    var otherNPC: NPC?
    var scene: Scene
    var day: Int
    var hour: Int
    var hasSuccess: Bool = false
    var isSuccess: Bool = false
    var isSignleNpcEvent: Bool { get { otherNPC == nil && interactionType.isStandalone }}
    var isDiscussed = false
    
    init(interactionType: NPCInteraction, currentNPC: NPC, otherNPC: NPC? = nil, scene: Scene, day: Int, hour: Int, hasSuccess: Bool = false, isSuccess: Bool = false) {
        self.interactionType = interactionType
        self.currentNPC = currentNPC
        self.otherNPC = otherNPC
        self.scene = scene
        self.day = day
        self.hour = hour
        self.hasSuccess = hasSuccess
        self.isSuccess = isSuccess
    }
    
    func markAsDiscussed() {
        isDiscussed = true
    }
}
