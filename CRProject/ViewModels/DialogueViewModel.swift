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
            options = [
                DialogueOption(
                    text: "Leave",
                    type: .normal,
                    nextNodeId: "end"
                )
            ]
        }
    }
    
    private func updateDialogue(text: String, options: [DialogueNodeOption]) {
        DebugLogService.shared.log("Updating dialogue - Text: \(text), Options count: \(options.count)", category: "Dialogue")
        currentDialogueText = text
        
        // Convert options and reorder if investigate option exists
        var dialogueOptions = options.map { option in
            DialogueOption(
                text: option.text,
                type: option.type,
                nextNodeId: option.nextNode
            )
        }
        
        // If there's an investigate option, move it to the beginning
        if let investigateIndex = dialogueOptions.firstIndex(where: { $0.type == .investigate }) {
            let investigateOption = dialogueOptions.remove(at: investigateIndex)
            dialogueOptions.insert(investigateOption, at: 0)
        }
        
        self.options = dialogueOptions
    }
    
    func selectOption(_ option: DialogueOption) {
        switch option.type {
        case .intimidate:
            handleIntimidation(nextNodeId: option.nextNodeId)
        case .seduce:
            handleSeduction(nextNodeId: option.nextNodeId)
        case .investigate:
            handleInvestigation(nextNodeId: option.nextNodeId)
        case .loveForSail:
            handleLoveForSail(nextNodeId: option.nextNodeId)
        case .normal:
            processNextNode(option.nextNodeId)
        case .intrigue:
            processNextNode(option.nextNodeId)
        }
    }
    
    private func handleIntimidation(nextNodeId: String) {
        let success = dialogueProcessor.attemptIntimidation()
        showActionResult(success: success, action: "Intimidation")
        
        if success {
            VibrationService.shared.lightTap()
            gameStateService.handleTimeAdvanced()
            processNextNode(nextNodeId)
        }
        
        gameStateService.handleTimeAdvanced()
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
            processNextNode(nextNodeId)
        }
    }
    
    private func handleLoveForSail(nextNodeId: String) {
        guard let player = gameStateService.player else { return }
        
        let cost = NPCInteraction.prostitution.interactionBaseCost
        
        if player.coins.couldRemove(cost) {
            // Sufficient funds: Proceed with transaction and next node
            CoinsManagementService.shared.moveCoins(from: player, to: npc, amount: cost)
            npc.playerRelationship.increase(amount: 5)
            
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
                     self.processNextNode(nextNodeId)
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
                processNextNode(nodeId)
                showActionResult(success: success, action: "Seduction")
            }
        } else {
            showActionResult(success: false, action: "Seduction")
            
            if let currentSceneId = gameStateService.currentScene?.id {
                vampireNatureRevealService.increaseAwareness(amount: 20)
            }
        }
        
        gameStateService.handleTimeAdvanced()
        pendingSeductionNode = nil
    }
    
    private func processNextNode(_ nodeId: String) {
        DebugLogService.shared.log("Processing node: \(nodeId)", category: "Dialogue")
        
        if nodeId == "end" {
            DebugLogService.shared.log("Node is 'end', setting shouldDismiss = true", category: "Dialogue")
            shouldDismiss = true
            return
        }
        
        if let nextDialogue = dialogueProcessor.processNode(nodeId) {
            DebugLogService.shared.log("DialogueProcessor returned dialogue for node \(nodeId). Text: \(nextDialogue.text)", category: "Dialogue")
            updateDialogue(text: nextDialogue.text, options: nextDialogue.options)
        } else {
            DebugLogService.shared.log("DialogueProcessor returned nil for node \(nodeId). Dialogue state will not change.", category: "Dialogue")
        }
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

struct DialogueOption: Identifiable {
    let id = UUID()
    let text: String
    let type: DialogueOptionType
    let nextNodeId: String
} 
