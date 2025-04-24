// MARK: - Dialogue Processor

class DialogueProcessor {
    private let dialogueSystem: DialogueSystem
    private let player: Player
    private var npc: NPC
    private var dialogueTree: DialogueTree?
    private var gameTimeService: GameTimeService
    private var gameStateService: GameStateService
    
    var currentNode: DialogueNode?
    var currentNodeId: String?
    
    init(dialogueSystem: DialogueSystem, player: Player, npc: NPC) {
        self.dialogueSystem = dialogueSystem
        self.player = player
        self.npc = npc
        self.gameTimeService = DependencyManager.shared.resolve()
        self.gameStateService = DependencyManager.shared.resolve()
    }
    
    func loadDialogue(npc: NPC) -> (text: String, options: [DialogueNodeOption])? {
        // Step 1: Load base dialogue tree
        var baseTree: DialogueTree?
        if let uniqueTree = dialogueSystem.getDialogueTree(for: npc.profession.rawValue, player: player, npcId: npc.id) {
            baseTree = uniqueTree
        } else if npc.profession != .noProfession,
                  let professionTree = dialogueSystem.getDialogueTree(for: npc.profession.rawValue, player: player) {
            baseTree = professionTree
        } else {
            baseTree = dialogueSystem.getGeneralDialogueTree()
        }
        
        guard var tree = baseTree else { 
            // If no dialogue found, return a basic "Leave" option
            return ("...", [DialogueNodeOption(from: "Leave", to: "end", type: .normal)])
        }
        
        // Step 2: If relationship >= 5, merge gossip nodes into the tree
        if npc.playerRelationship.value >= 5 {
            tree = mergeGossipNodes(into: tree)
        }
        
        // Store the complete tree
        self.dialogueTree = tree
        
        // Get initial node
        let initialNodeId = npc.hasInteractedWithPlayer ? "joan_greeting_return" : tree.initialNode
        if var node = tree.nodes[initialNodeId] {
            node = filterGeneralOptions(npc: npc, node: node)!
            currentNode = node
            return (node.text, filterAvailableOptions(options: node.options))
        }
        
        return nil
    }
    
    private func mergeGossipNodes(into baseTree: DialogueTree) -> DialogueTree {
        var nodes = baseTree.nodes
        
        // Step 1: Generate gossip events
        let gossipEvents = GossipGeneratorService.shared.generateRawGossipEvents(for: npc)
        guard !gossipEvents.isEmpty else { return baseTree }
        
        // Step 2: Create linked list of gossip nodes
        for (index, event) in gossipEvents.enumerated() {
            let gossipNode = GossipGeneratorService.shared.generateGossipNode(for: npc, event: event)
            let nodeId = "gossip_\(index)"
            let nextNodeId = index < gossipEvents.count - 1 ? "gossip_\(index + 1)" : "gossip_end"
            
            // Each gossip node has two options:
            // 1. "Anything else?" -> next gossip or end gossip
            // 2. "Interesting..." -> back to initial dialogue
            let options = [
                DialogueNodeOption(from: "Anything else?", to: nextNodeId, type: .normal),
                DialogueNodeOption(from: "Interesting...", to: baseTree.initialNode, type: .normal)
            ]
            
            nodes[nodeId] = DialogueNode(text: gossipNode.text, options: options, requirements: nil)
        }
        
        // Add final gossip node
        nodes["gossip_end"] = DialogueNode(
            text: "Actually, that seems to be all the news I have for now.",
            options: [
                DialogueNodeOption(from: "Thank you for sharing.", to: baseTree.initialNode, type: .normal),
                DialogueNodeOption(from: "Goodbye.", to: "end", type: .normal)
            ],
            requirements: nil
        )
        
        // Step 3: Add gossip entry point to all relevant nodes
        for (nodeId, node) in nodes {
            if nodeId == baseTree.initialNode || nodeId == "joan_greeting_return" {
                var options = node.options
                options.append(DialogueNodeOption(
                    from: "What's new in town?",
                    to: "gossip_0",
                    type: .normal
                ))
                nodes[nodeId] = DialogueNode(text: node.text, options: options, requirements: node.requirements)
            }
        }
        
        return DialogueTree(initialNode: baseTree.initialNode, nodes: nodes)
    }
    
    func processNode(_ nodeId: String) -> (text: String, options: [DialogueNodeOption])? {
        if nodeId == "end" {
            DebugLogService.shared.log("Dialogue ended via explicit 'end' node ID.", category: "Dialogue")
            return nil
        }
        
        guard let tree = dialogueTree,
              var node = tree.nodes[nodeId] else {
            DebugLogService.shared.log("Error: Could not find node with ID: \(nodeId). Ending dialogue.", category: "Error")
            return nil
        }
        
        node = filterGeneralOptions(npc: npc, node: node) ?? node
        currentNode = node
        currentNodeId = nodeId
        return (node.text, filterAvailableOptions(options: node.options))
    }
    
    func normalizeRelationshipNode( _ nodeText: String) {
        guard let options = currentNode?.options else { return }
        
        for option in options {
            if option.text == nodeText && option.type == .relationshipIncrease || option.type == .relationshipDecrease {
                option.type = .normal
            }
        }
        
    }
    
    func filterGeneralOptions(npc: NPC, node: DialogueNode?) -> DialogueNode? {
        guard let node = node else { return nil }
        
        var filteredOptions = node.options
        
        // Filter options based on first conversation
        if npc.isFirstConversation {
            filteredOptions = filteredOptions.filter { option in
                // Only show options that are appropriate for first meeting
                return option.type == .normal || 
                       option.type == .investigate || 
                       option.type == .relationshipIncrease ||
                       option.type == .relationshipDecrease
            }
        }
        
        // Filter options for known NPCs
        if !npc.isUnknown {
            filteredOptions = filteredOptions.filter { $0.type != .investigate }
        }
        
        // Filter options for intimidated NPCs
        if npc.isIntimidated {
            filteredOptions = filteredOptions.filter { $0.type != .intrigue }
        }
        // For unknown NPCs, remove seduction and intrigue options
        else if npc.isUnknown {
            filteredOptions = filteredOptions.filter { option in 
                option.type != .intrigue && 
                option.type != .seduce
            }
        }
        
        return DialogueNode(
            text: node.text,
            options: filteredOptions,
            requirements: node.requirements
        )
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
        
        if let minRelationship = req.minRelationship,
           npc.playerRelationship.value < minRelationship {
            return false
        }
        
        if let maxRelationship = req.maxRelationship,
           npc.playerRelationship.value > maxRelationship {
            return false
        }
        
        return true
    }
    
    private func filterAvailableOptions(options: [DialogueNodeOption]) -> [DialogueNodeOption] {
        return options.filter(meetsRequirements)
    }
}
