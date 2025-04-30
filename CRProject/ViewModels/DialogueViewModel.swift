import Foundation
import Combine
import SwiftUI

class DialogueViewModel: ObservableObject {
    @Published var currentDialogueText: String = ""
    @Published var options: [DialogueOption] = []
    @Published var showActionResult: Bool = false
    @Published var actionResultSuccess: Bool = false
    @Published var actionResultMessage: String = ""
    @Published var showHypnosisGame: Bool = false
    @Published var hypnosisScore: Int = 0
    @Published var showLoveScene: Bool = false
    @Published var shouldDismiss: Bool = false
    
    @Published var npc: NPC
    private let dialogueProcessor: DialogueProcessor
    private var cancellables = Set<AnyCancellable>()
    private var pendingSeductionNode: String?
    
    private let vampireNatureRevealService: VampireNatureRevealService = DependencyManager.shared.resolve()
    private let gameStateService: GameStateService = DependencyManager.shared.resolve()
    private let gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    private let investigationService: InvestigationService = DependencyManager.shared.resolve()
    
    init(npc: NPC, player: Player) {
        if npc.isUnknown {
            InvestigationService.shared.investigate(inspector: player, investigationObject: npc)
        }
        self.npc = npc
        self.dialogueProcessor = DialogueProcessor(
            dialogueSystem: DialogueSystem.load(),
            player: player,
            npc: npc
        )
        
        DebugLogService.shared.log("Initializing dialogue for NPC: \(npc.name), profession: \(npc.profession)", category: "Dialogue")
        loadInitialDialogue()
        // Mark that the player has interacted with this NPC
        npc.hasInteractedWithPlayer = true
    }
    
    private func loadInitialDialogue() {
        DebugLogService.shared.log("Attempting to load dialogue for NPC: \(npc.name), profession: \(npc.profession.rawValue)", category: "Dialogue")
        
        // Try profession-specific dialogue first
        if let dialogue = dialogueProcessor.loadDialogue(npc: npc) {
            
            DebugLogService.shared.log("Successfully loaded dialogue for \(npc.profession.rawValue)", category: "Dialogue")
            updateDialogue(text: dialogue.text, options: dialogue.options)
        } else {
            // If we reach here, both profession-specific and general dialogue failed
            DebugLogService.shared.log("Failed to load any dialogue for \(npc.profession.rawValue)", category: "Error")
            currentDialogueText = "..."
            options = [getEndOption()]
        }
    }
    
    private func getEndOption() -> DialogueOption {
        let option = DialogueOption()
        option.type = .normal
        option.text = "Leave"
        option.nextNodeId = "end"
        return option
    }
    
    private func updateDialogue(text: String, options: [DialogueNodeOption]) {
        DebugLogService.shared.log("Updating dialogue VM - Text: \(text), Options count: \(options.count)", category: "DialogueVM")
        
        self.currentDialogueText = ""
        self.options = []
        // Update state directly without animation
        self.currentDialogueText = text
        
        let mappedOptions = options.map { option in
            DialogueOption.create(text: option.text, type: option.type, nextNodeId: option.nextNode)
        }

        self.options = mappedOptions
        DebugLogService.shared.log("Assigned options count: \(self.options.count)", category: "DialogueVM")
    }
    
    func selectOption(_ option: DialogueOption) {
        DebugLogService.shared.log("Selected option leading to node: \(option.nextNodeId)", category: "DialogueVM")
        
        // Use a switch statement for different option types
        switch option.type {
        case .intimidate:
            handleIntimidation(nextNodeId: option.nextNodeId)
        case .seduce:
            handleSeduction(nextNodeId: option.nextNodeId)
        case .investigate:
            handleInvestigation(nextNodeId: option.nextNodeId)
        case .loveForSail:
            handleLoveForSail(nextNodeId: option.nextNodeId)
        case .relationshipIncrease:
            dialogueProcessor.normalizeRelationshipNode(option.text)
            handleRelationshipIncrease(nextNodeId: option.nextNodeId, option: option.text)
        case .relationshipDecrease:
            dialogueProcessor.normalizeRelationshipNode(option.text)
            handleRelationshipDecrease(nextNodeId: option.nextNodeId, option: option.text)
        case .normal, .intrigue:
            // Process all nodes consistently, including gossip
            if let (newText, newOptions) = dialogueProcessor.processNode(option.nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
        case .askingForSmithingPermission:
            handleAskingForSmithingPermission(nextNodeId: option.nextNodeId)
        case .askingForAlchemyPermission:
            handleAskingForAlchemyPermission(nextNodeId: option.nextNodeId)
        case .askingForDesiredVictim:
            handleAskForDesiredVictim(nextNodeId: option.nextNodeId)
        case .desiredVictimBribe:
            handleDesiredVictimBribe(nextNodeId: option.nextNodeId)
        case .fakeAlibiesBribe:
            handleFakeAlibiesBribe(nextNodeId: option.nextNodeId)
        case .overlookActivitiesIntimidation:
            handleOverlookActivitiesIntimidation(nextNodeId: option.nextNodeId)
        case .askingForFakeAlibies:
            // This is no longer used, but kept for backward compatibility
            if let (newText, newOptions) = dialogueProcessor.processNode(option.nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
        }
    }
    
    private func handleIntimidation(nextNodeId: String) {
        let success = dialogueProcessor.attemptIntimidation(npc: npc)
        showActionResult(success: success, action: "Intimidation")
        
        if success {
            VibrationService.shared.lightTap()
            gameStateService.handleTimeAdvanced()
            // Process the next node *after* showing the result (or integrate result display differently)
            if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
        } else {
            // If intimidation fails, do we stay on the same node or go somewhere else?
            // If staying, no need to call processNode. If going elsewhere, call processNode for that ID.
             gameStateService.handleTimeAdvanced() // Advance time even on failure?
        }
    }
    
    private func handleSeduction(nextNodeId: String) {
        pendingSeductionNode = nextNodeId
        VibrationService.shared.lightTap()
        showHypnosisGame = true
    }
    
    private func handleAskForDesiredVictim(nextNodeId: String) {
        guard let player = gameStateService.player else { return }
        
        // Check if this is the initial request from player (right after asking about someone)
        if nextNodeId == "offer_payment_for_info" {
            // Use the DialogueProcessor's method to determine success
            let success = dialogueProcessor.attemptPersuasion(with: npc)
            
            if success {
                // Successful persuasion - NPC is willing to share information for a price
                // Process the success node - offer to provide info for payment
                if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                    updateDialogue(text: newText, options: newOptions)
                } else {
                    shouldDismiss = true
                }
                
                // Show success message
                showActionResult(success: true, action: "Persuasion")
                VampireNatureRevealService.shared.increaseAwareness(amount: 5)
                
                // Haptic feedback
                VibrationService.shared.lightTap()
            } else {
                // Failed persuasion - NPC is not willing to share information
                // No money is exchanged
                
                // Larger relationship decrease - NPC is offended by the bribe attempt
                npc.playerRelationship.decrease(amount: 1)
                
                // Process the failure node instead
                if let (newText, newOptions) = dialogueProcessor.processNode("bribe_attempt_fail") {
                    updateDialogue(text: newText, options: newOptions)
                } else {
                    shouldDismiss = true
                }
                
                // Add an event to the game events bus
                GameEventsBusService.shared.addMessageWithIcon(
                    type: .common,
                    location: GameStateService.shared.currentScene?.name ?? "Unknown",
                    player: player,
                    secondaryNPC: npc,
                    interactionType: .conversation,
                    hasSuccess: true,
                    isSuccess: false
                )
                
                // Show failure message
                showActionResult(success: false, action: "Persuasion")
                VampireNatureRevealService.shared.increaseAwareness(amount: 10)
                
                // Haptic feedback
                VibrationService.shared.errorVibration()
            }
            
            // Advance time for the persuasion attempt
            GameTimeService.shared.advanceTime()
            
            npc.isIntimidated = true
            npc.intimidationDay = GameTimeService.shared.currentDay
            return
        }
        
        // For any other nodes in this dialogue chain, just process them normally
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func handleDesiredVictimBribe(nextNodeId: String) {
        guard let player = gameStateService.player else { return }
        
        // Handle payment nodes (after successful persuasion)
        if nextNodeId == "bribe_success_victim_info" || nextNodeId == "no_matching_npcs" {
            // Player is paying for information (this happens after successful persuasion)
            // Update coins
            CoinsManagementService.shared.moveCoins(from: player, to: npc, amount: 100)
            
            // Register a bribe in statistics
            StatisticsService.shared.increaseBribes()
            
            // If this is the success information node
            if nextNodeId == "bribe_success_victim_info" {
                // Successful information exchange
                // Slightly increase the NPC's relationship with the player
                npc.playerRelationship.increase(amount: 1)
                
                // Add an event to the game events bus
                GameEventsBusService.shared.addMessageWithIcon(
                    type: .common,
                    location: GameStateService.shared.currentScene?.name ?? "Unknown",
                    player: player,
                    secondaryNPC: npc,
                    interactionType: .conversation,
                    hasSuccess: true,
                    isSuccess: true
                )
            } else {
                CoinsManagementService.shared.moveCoins(from: npc, to: player, amount: 100)
                
                // No matching NPCs but payment was made
                GameEventsBusService.shared.addMessageWithIcon(
                    type: .common,
                    location: GameStateService.shared.currentScene?.name ?? "Unknown",
                    player: player,
                    secondaryNPC: npc,
                    interactionType: .conversation,
                    hasSuccess: true,
                    isSuccess: nil
                )
            }
            
            // Process the node
            if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
            
            // Advance time for the information exchange
            GameTimeService.shared.advanceTime()
        } else {
            // For any other nodes, just process them normally
            if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
        }
    }
    
    private func handleInvestigation(nextNodeId: String) {
        if let player = gameStateService.player {
            investigationService.investigate(inspector: player, investigationObject: npc)
            VibrationService.shared.lightTap()
            if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
        }
    }
    
    private func handleLoveForSail(nextNodeId: String) {
        guard let player = gameStateService.player else { return }
        
        let cost = NPCInteraction.prostitution.interactionBaseCost
        
        if player.coins.couldRemove(cost) {
            // Sufficient funds: Proceed with transaction and next node
            CoinsManagementService.shared.moveCoins(from: player, to: npc, amount: cost)
            npc.playerRelationship.increase(amount: 1)
            npc.spentNightWithPlayer = true
            
            VibrationService.shared.lightTap()
            
            // --- Restoring Love Scene Logic ---
            withAnimation(.easeIn(duration: 0.5)) {
                showLoveScene = true
            }
            
            // Hide love scene after 5 seconds with smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                // Ensure self is still valid
                guard let self = self else { return }
                
                withAnimation(.easeOut(duration: 0.5)) {
                    self.showLoveScene = false
                }
                // Process next node after hiding animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                     // Ensure self is still valid before processing node
                     guard let self = self else { return }
                     if let (newText, newOptions) = self.dialogueProcessor.processNode(nextNodeId) {
                         self.updateDialogue(text: newText, options: newOptions)
                     } else {
                         self.shouldDismiss = true
                     }
                }
            }
            // --- End Restored Logic ---

            GameEventsBusService.shared.addMessageWithIcon(
                type: .common,
                location: GameStateService.shared.currentScene?.name ?? "Unknown",
                player: player,
                secondaryNPC: npc,
                interactionType: NPCInteraction.prostitution,
                hasSuccess: false,
                isSuccess: nil
            )
        } else {
            // Insufficient funds: Show failure message and DO NOT proceed
            showActionResult(success: false, action: "Payment")
            GameEventsBusService.shared.addWarningMessage("* Not enough coins! *")
        }
        
        GameTimeService.shared.advanceTime()
    }
    
    private func handleRelationshipIncrease(nextNodeId: String, option: String) {
        npc.playerRelationship.increase(amount: 1)
        GameStateService.shared.player?.processRelationshipDialogueNode(option: option)
        VibrationService.shared.lightTap()
        // Directly process the next node
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func handleAskingForSmithingPermission(nextNodeId: String) {
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func handleAskingForAlchemyPermission(nextNodeId: String) {
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func handleRelationshipDecrease(nextNodeId: String, option: String) {
        npc.playerRelationship.decrease(amount: 1)
        GameStateService.shared.player?.processRelationshipDialogueNode(option: option)
        VibrationService.shared.lightTap()
        // Directly process the next node
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func handleFakeAlibiesBribe(nextNodeId: String) {
        guard let player = gameStateService.player else { return }
        
        // Check if player has enough coins
        if player.coins.value >= 150 {
            // Player pays for the fake alibi
            CoinsManagementService.shared.moveCoins(from: player, to: npc, amount: 150)
            
            // Increase player-NPC relationship
            npc.playerRelationship.increase(amount: 2)
            
            // Reduce awareness - the alibi helps cover player's activities
            vampireNatureRevealService.decreaseAwareness(amount: 15)
            
            // Set NPC as alibi provider for player
            npc.isIntimidated = true
            
            // Process the success node
            if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
            
            // Add a game event
            GameEventsBusService.shared.addMessageWithIcon(
                type: .common,
                location: GameStateService.shared.currentScene?.name ?? "Unknown",
                player: player,
                secondaryNPC: npc,
                interactionType: .conversation,
                hasSuccess: true,
                isSuccess: true
            )
            
            // Increment statistics for bribes - this helps with Silver Tongue ability
            StatisticsService.shared.increaseBribes()
            
            // Show success message
            showActionResult(success: true, action: "Arranged Alibi")
            
            // Haptic feedback
            VibrationService.shared.lightTap()
        } else {
            // Not enough coins - this should be caught by the UI requirements,
            // but handle it gracefully just in case
            GameEventsBusService.shared.addWarningMessage("* Not enough coins! *")
            showActionResult(success: false, action: "Not enough coins")
            
            // Try to go back to initial dialogue
            if let initialNodeId = dialogueProcessor.dialogueTree?.initialNode,
               let (newText, newOptions) = dialogueProcessor.processNode(initialNodeId) {
                updateDialogue(text: newText, options: newOptions)
            }
            
            // Haptic feedback
            VibrationService.shared.errorVibration()
        }
        
        // Advance time for the transaction
        GameTimeService.shared.advanceTime()
    }
    
    private func handleOverlookActivitiesIntimidation(nextNodeId: String) {
        guard let player = gameStateService.player else { return }
        
        // For Mysterious Person ability, success is based on intimidation
        let success = dialogueProcessor.attemptIntimidation(npc: npc)
        
        // Set NPC as intimidated
        npc.isIntimidated = true
        npc.intimidationDay = GameTimeService.shared.currentDay
        
        if success {
            // Successful intimidation - NPC is intimidated into overlooking activities
            
            // Decrease relationship - even if successful, intimidation damages relationship
            npc.playerRelationship.decrease(amount: 1)
            
            // Reduce awareness substantially - the NPC won't report suspicious activities
            vampireNatureRevealService.decreaseAwareness(amount: 4)
            
            // Process the success node
            if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
            
            // Add a game event
            GameEventsBusService.shared.addMessageWithIcon(
                type: .common,
                location: GameStateService.shared.currentScene?.name ?? "Unknown",
                player: player,
                secondaryNPC: npc,
                interactionType: .conversation,
                hasSuccess: true,
                isSuccess: true
            )
            
            // Show success message
            showActionResult(success: true, action: "Intimidation")
            
            // Haptic feedback
            VibrationService.shared.lightTap()
        } else {
            // Failed intimidation - NPC refuses to be intimidated
            
            // Major relationship decrease - NPC is offended by intimidation attempt
            npc.playerRelationship.decrease(amount: 2)
            
            // Increase awareness - failed intimidation makes NPC more suspicious
            vampireNatureRevealService.increaseAwareness(amount: 10)
            
            // Process the failure node
            if let (newText, newOptions) = dialogueProcessor.processNode("overlook_fail") {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
            
            // Add a game event
            GameEventsBusService.shared.addMessageWithIcon(
                type: .common,
                location: GameStateService.shared.currentScene?.name ?? "Unknown",
                player: player,
                secondaryNPC: npc,
                interactionType: .conversation,
                hasSuccess: true,
                isSuccess: false
            )
            
            // Show failure message
            showActionResult(success: false, action: "Intimidation")
            
            // Haptic feedback
            VibrationService.shared.errorVibration()
        }
        
        // Advance time for the intimidation attempt
        GameTimeService.shared.advanceTime()
    }
    
    func onHypnosisGameComplete(score: Int) {
        hypnosisScore = score
        withAnimation(.linear(duration: 0.2)) {
            showHypnosisGame = false
        }
        
        if score >= 100, let nodeId = pendingSeductionNode {
            let success = dialogueProcessor.attemptSeduction()
            
            if success {
                npc.isIntimidated = true
                if let (newText, newOptions) = dialogueProcessor.processNode(nodeId) {
                    updateDialogue(text: newText, options: newOptions)
                } else {
                    shouldDismiss = true
                }
                showActionResult(success: success, action: "Seduction")
            }
        } else {
            showActionResult(success: false, action: "Seduction")
            vampireNatureRevealService.increaseAwareness(amount: 20)
        }
        
        gameStateService.handleTimeAdvanced()
        pendingSeductionNode = nil
    }
    
    private func showActionResult(success: Bool, action: String) {
        actionResultSuccess = success
        actionResultMessage = "\(action) \(success ? "succeeded" : "failed")"
        showActionResult = true
        
        // Hide the result after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showActionResult = false
        }
    }
}

class DialogueOption: Identifiable {
    var id = UUID()
    var text: String = ""
    var type: DialogueOptionType = .normal
    var nextNodeId: String = ""
    
    static func create(text: String, type: DialogueOptionType, nextNodeId: String? = nil) -> DialogueOption {
        let option = DialogueOption()
        option.id = UUID()
        option.text = text
        option.type = type
        option.nextNodeId = nextNodeId ?? ""
        return option
    }
}
