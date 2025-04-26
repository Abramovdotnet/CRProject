//
//  ChatMessage.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import Combine
import SwiftUI
import SwiftUICore
import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let timestampHour: Int
    let timestampDay: Int
    let timestampHourString: String
    let message: String
    let type: MessageType
    let location: String?
    let player: Player?
    let primaryNPC: NPC?
    let secondaryNPC: NPC?
    let interactionType: NPCInteraction?
    let hasSuccess: Bool
    let isSuccess: Bool?
    let isDiscussion: Bool
    let messageLocation: String?
    let rumorInteractionType: NPCInteraction?
    let rumorPrimaryNPC: NPC?
    let rumorSecondaryNPC: NPC?
    
    init(
        timestampHour: Int,
        timestampDay: Int,
        timestampHourString: String,
        message: String?,
        type: MessageType,
        location: String? = nil,
        player: Player? = nil,
        primaryNPC: NPC? = nil,
        secondaryNPC: NPC? = nil,
        interactionType: NPCInteraction? = nil,
        hasSuccess: Bool = false,
        isSuccess: Bool? = nil,
        isDiscussion: Bool = false,
        messageLocation: String? = nil,
        rumorInteractionType: NPCInteraction? = nil,
        rumorPrimaryNPC: NPC? = nil,
        rumorSecondaryNPC: NPC? = nil
    ) {
        self.timestampHour = timestampHour
        self.timestampDay = timestampDay
        self.timestampHourString = timestampHourString
        self.message = message ?? ""
        self.type = type
        self.location = location
        self.player = player
        self.primaryNPC = primaryNPC
        self.secondaryNPC = secondaryNPC
        self.interactionType = interactionType
        self.hasSuccess = hasSuccess
        self.isSuccess = isSuccess
        self.isDiscussion = isDiscussion
        self.messageLocation = messageLocation
        self.rumorInteractionType = rumorInteractionType
        self.rumorPrimaryNPC = rumorPrimaryNPC
        self.rumorSecondaryNPC = rumorSecondaryNPC
    }
}