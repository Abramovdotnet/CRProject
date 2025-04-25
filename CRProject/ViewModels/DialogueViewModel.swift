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
        if var dialogue = dialogueProcessor.loadDialogue(npc: npc) {
            
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
        
        var mappedOptions = options.map { option in
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
        }
    }
    
    private func handleIntimidation(nextNodeId: String) {
        let success = dialogueProcessor.attemptIntimidation()
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
        var option = DialogueOption()
        option.id = UUID()
        option.text = text
        option.type = type
        option.nextNodeId = nextNodeId ?? ""
        return option
    }
}
