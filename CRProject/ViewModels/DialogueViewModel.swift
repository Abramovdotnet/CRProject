import Foundation
import Combine

class DialogueViewModel: ObservableObject {
    @Published var currentDialogueText: String = ""
    @Published var options: [DialogueOption] = []
    @Published var showActionResult: Bool = false
    @Published var actionResultSuccess: Bool = false
    @Published var actionResultMessage: String = ""
    
    let npc: NPC
    private let dialogueProcessor: DialogueProcessor
    private var cancellables = Set<AnyCancellable>()
    
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
        if let dialogue = dialogueProcessor.loadDialogue(profession: npc.profession) {
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
        self.options = options.map { option in
            DialogueOption(
                text: option.text,
                type: option.type,
                nextNodeId: option.nextNode
            )
        }
    }
    
    func selectOption(_ option: DialogueOption) {
        switch option.type {
        case .intimidate:
            handleIntimidation(nextNodeId: option.nextNodeId)
        case .seduce:
            handleSeduction(nextNodeId: option.nextNodeId)
        case .normal:
            processNextNode(option.nextNodeId)
        }
    }
    
    private func handleIntimidation(nextNodeId: String) {
        let success = dialogueProcessor.attemptIntimidation()
        showActionResult(success: success, action: "Intimidation")
        
        if success {
            processNextNode(nextNodeId)
        }
    }
    
    private func handleSeduction(nextNodeId: String) {
        let success = dialogueProcessor.attemptSeduction()
        showActionResult(success: success, action: "Seduction")
        
        if success {
            processNextNode(nextNodeId)
        }
    }
    
    private func processNextNode(_ nodeId: String) {
        if nodeId == "end" {
            // Handle end of dialogue
            currentDialogueText = "The conversation has ended."
            options = []
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
