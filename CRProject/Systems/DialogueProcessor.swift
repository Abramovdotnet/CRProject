// MARK: - Dialogue Processor

class DialogueProcessor {
    private let dialogueSystem: DialogueSystem
    private let player: Player
    private var npc: NPC
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
    
    func loadDialogue(npc: NPC) -> (text: String, options: [DialogueNodeOption])? {
        // Try to load profession-specific dialogue first
        if npc.profession != .general {
            if let tree = dialogueSystem.getDialogueTree(for: npc.profession.rawValue) {
                currentTree = tree
                if var node = tree.nodes[tree.initialNode] {
                    node = filterGeneralOptions(npc: npc, node: node)!
                    currentNode = node
                    return (node.text, filterAvailableOptions(options: node.options))
                }
            }
        }
        
        // If no profession dialogue found or if .general was requested, try general dialogue
        if let generalTree = dialogueSystem.getGeneralDialogueTree() {
            currentTree = generalTree
            if var node = generalTree.nodes[generalTree.initialNode] {
                node = filterGeneralOptions(npc: npc, node: node)!
                currentNode = node
                return (node.text, filterAvailableOptions(options: node.options))
            }
        }
        
        return nil
    }
    
    func filterGeneralOptions(npc: NPC, node: DialogueNode?) -> DialogueNode? {
        guard let node = node else { return nil }
        
        var filteredOptions = node.options
        
        // Фильтрация для известных NPC
        if !npc.isUnknown {
            filteredOptions = filteredOptions.filter { $0.type != .investigate }
        }
        
        // Фильтрация для запуганных NPC
        if npc.isIntimidated {
            filteredOptions = filteredOptions.filter { $0.type != .intrigue }
        }
        // Для неизвестных NPC убираем соблазнение и интриги
        else if npc.isUnknown {
            filteredOptions = filteredOptions.filter { option in option.type != .intrigue
            }
        }
        
        return DialogueNode(
            text: node.text,
            options: filteredOptions,
            requirements: node.requirements
        )
    }
    
    func processNode(_ nodeId: String) -> (text: String, options: [DialogueNodeOption])? {
        guard let tree = currentTree,
              var node = tree.nodes[nodeId] else {
            return nil
        }
        node = filterGeneralOptions(npc: npc, node: node) ?? node
        currentNode = node
        return (node.text, filterAvailableOptions(options: node.options))
    }
    
    func attemptIntimidation() -> Bool {
        let finalChance = 70
        return Int.random(in: 1...100) <= finalChance
    }
    
    func attemptSeduction() -> Bool {
        return true
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
