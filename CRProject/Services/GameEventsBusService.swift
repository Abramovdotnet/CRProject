//
//  GameEventsBusService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 03.04.2025.
//

import Foundation
import Combine
import SwiftUICore

extension Optional where Wrapped == String {
    func orEmpty() -> String {
        return self ?? ""
    }
}

class GameEventsBusService: GameService, ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    static let shared: GameEventsBusService = DependencyManager.shared.resolve()
    private let gameTimeService: GameTimeService
    private let maxMessages = 50
    private var cancellables = Set<AnyCancellable>()
    
    init(gameTimeService: GameTimeService = DependencyManager.shared.resolve()) {
        self.gameTimeService = gameTimeService
        // Initialize with some system message if needed
        addMessage(
            message: "Game session started",
            type: .system
        )
        
        NotificationCenter.default
            .publisher(for: .nightAppears)
            .sink { [weak self] _ in
                self?.addWarningMessage("Night falls across the land...")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: .dayAppears)
            .sink { [weak self] _ in
                self?.addWarningMessage("Dawn breaks, a new day begins.")
            }
            .store(in: &cancellables)
    }
    
    func addMessage(message: String? = nil, type: MessageType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let newMessage = ChatMessage(
                timestampHour: gameTimeService.currentHour,
                timestampDay: gameTimeService.currentDay,
                timestampHourString: gameTimeService.currentHour.description + ":00  -",
                message: message,  // Pass the optional, let ChatMessage handle it
                type: type
            )
            
            // Queue mechanism - remove first if at capacity
            if self.messages.count >= self.maxMessages {
                self.messages.removeFirst()
            }
            
            self.messages.append(newMessage)
        }
    }
    
    func addMessageWithIcon(
        message: String? = nil,
        type: MessageType,
        location: String? = nil,
        primaryNPC: NPC? = nil,
        player: Player? = nil,
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let newMessage = ChatMessage(
                timestampHour: gameTimeService.currentHour,
                timestampDay: gameTimeService.currentDay,
                timestampHourString: gameTimeService.currentHour.description + ":00 -",
                message: message,
                type: type,
                location: location,
                player: player,
                primaryNPC: primaryNPC,
                secondaryNPC: secondaryNPC,
                interactionType: interactionType,
                hasSuccess: hasSuccess,
                isSuccess: isSuccess,
                isDiscussion: isDiscussion,
                messageLocation: messageLocation,
                rumorInteractionType: rumorInteractionType,
                rumorPrimaryNPC: rumorPrimaryNPC,
                rumorSecondaryNPC: rumorSecondaryNPC
            )
            
            // Queue mechanism - remove first if at capacity
            if self.messages.count >= self.maxMessages {
                self.messages.removeFirst()
            }
            
            self.messages.append(newMessage)
        }
    }
    
    func clearChatHistory() {
        DispatchQueue.main.async { [weak self] in
            self?.messages.removeAll()
            
            // Optionally add a system message after clearing
            self?.addMessage(
                message: "Chat history cleared",
                type: .system
            )
        }
    }
    
    // Legacy version for backward compatibility
    func addMessageWithIcon(message: String? = nil, icon: String? = nil, iconColor: Color? = nil, type: MessageType) {
        addMessageWithIcon(
            message: message,
            type: type,
            location: nil,
            primaryNPC: nil,
            secondaryNPC: nil,
            interactionType: nil,
            hasSuccess: false,
            isSuccess: nil,
            isDiscussion: false
        )
    }
    
    // Helper methods for common message types
    func addSystemMessage(_ message: String? = nil) {
        addMessage(message: message, type: .system)
    }

    func addWarningMessage(_ message: String? = nil) {
        addMessage(message: message, type: .warning)
    }

    func addEventMessage(_ message: String? = nil) {
        addMessage(message: message, type: .event)
    }

    func addDialogueMessage(message: String? = nil) {
        addMessage(message: message, type: .dialogue)
    }
    
    func addDangerMessage(message: String? = nil) {
        addMessage(message: message, type: .danger)
    }

    func addCommonMessage(message: String? = nil) {
        addMessage(message: message, type: .common)
    }
}
