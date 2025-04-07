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
    
    @Published var npc: NPC
    private let dialogueProcessor: DialogueProcessor
    private var cancellables = Set<AnyCancellable>()
    private var pendingSeductionNode: String?
    
    private let vampireNatureRevealService: VampireNatureRevealService = DependencyManager.shared.resolve()
    private let gameStateService: GameStateService = DependencyManager.shared.resolve()
    private let gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    private let investigationService: InvestigationService = DependencyManager.shared.resolve()
    
    init(npc: NPC, player: Player) {
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
                vampireNatureRevealService.increaseAwareness(for: currentSceneId, amount: 20)
            }
        }
        
        gameStateService.handleTimeAdvanced()
        pendingSeductionNode = nil
    }
    
    private func processNextNode(_ nodeId: String) {
        if nodeId == "end" {
            // Return to initial dialogue instead of ending conversation
            loadInitialDialogue()
            return
        }
        
        if let nextDialogue = dialogueProcessor.processNode(nodeId) {
            updateDialogue(text: nextDialogue.text, options: nextDialogue.options)
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
