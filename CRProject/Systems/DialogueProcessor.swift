// MARK: - Dialogue Processor
class DialogueProcessor {
    private let dialogueSystem: DialogueSystem
    private let player: Player
    private let npc: NPC
    private var currentNode: DialogueNode?
    private var currentTree: DialogueTree?
    private var gameTimeService: GameTimeService
    private var gameStateService: GameStateService
    
    init(dialogueSystem: DialogueSystem, player: Player, npc: NPC) {
        self.dialogueSystem = dialogueSystem
        self.player = player
        self.npc = npc
        self.gameTimeService = DependencyManager.shared.resolve()
        self.gameStateService = DependencyManager.shared.resolve()
    }
    
    func loadDialogue(profession: Profession) -> (text: String, options: [DialogueNodeOption])? {
        // Try to load profession-specific dialogue first
        if profession != .general {
            if let tree = dialogueSystem.getDialogueTree(for: profession.rawValue) {
                currentTree = tree
                if let node = tree.nodes[tree.initialNode] {
                    currentNode = node
                    return (node.text, filterAvailableOptions(options: node.options))
                }
            }
        }
        
        // If no profession dialogue found or if .general was requested, try general dialogue
        if let generalTree = dialogueSystem.getGeneralDialogueTree() {
            currentTree = generalTree
            if let node = generalTree.nodes[generalTree.initialNode] {
                currentNode = node
                return (node.text, filterAvailableOptions(options: node.options))
            }
        }
        
        return nil
    }
    
    func processNode(_ nodeId: String) -> (text: String, options: [DialogueNodeOption])? {
        guard let tree = currentTree,
              let node = tree.nodes[nodeId] else {
            return nil
        }
        currentNode = node
        return (node.text, filterAvailableOptions(options: node.options))
    }
    
    func attemptIntimidation() -> Bool {
        let finalChance = 70
        return Int.random(in: 1...100) <= finalChance
    }
    
    func attemptSeduction() -> Bool {
        let finalChance = 70
        return Int.random(in: 1...100) <= finalChance
    }
    
    private func meetsRequirements(_ option: DialogueNodeOption) -> Bool {
        guard let req = option.requirements else { return true }
        
        if let isNight = req.isNight, isNight != gameTimeService.isNightTime {
            return false
        }
        
        if let isIndoor = req.isIndoor,
           let currentScene = gameStateService.currentScene,
           isIndoor != currentScene.isIndoor {
            return false
        }
        
        return true
    }
    
    private func filterAvailableOptions(options: [DialogueNodeOption]) -> [DialogueNodeOption] {
        return options.filter(meetsRequirements)
    }
}
