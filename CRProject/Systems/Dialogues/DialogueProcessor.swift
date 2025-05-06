// MARK: - Dialogue Processor

class DialogueProcessor {
    private let dialogueSystem: DialogueSystem
    private let player: Player
    private var npc: NPC
    var dialogueTree: DialogueTree?
    private var gameTimeService: GameTimeService
    private var gameStateService: GameStateService
    
    var currentNode: DialogueNode?
    var currentNodeId: String?
    
    // Constants for placeholders
    private static let returnToMainPlaceholder = "RETURN_TO_MAIN_DIALOGUE_ROOT"
    private static let proceedToEndPlaceholder = "PROCEED_TO_END"

    init(dialogueSystem: DialogueSystem, player: Player, npc: NPC) {
        self.dialogueSystem = dialogueSystem
        self.player = player
        self.npc = npc
        self.gameTimeService = DependencyManager.shared.resolve()
        self.gameStateService = DependencyManager.shared.resolve()
    }
    
    // Public method to get the current node ID
    func getCurrentNodeId() -> String? {
        return currentNodeId
    }
    
    private func processConditionalText(_ text: String) -> String {
        var processedText = text
        
        // Handle first meeting condition
        if processedText.contains("{if:first_meeting}") {
            let isFirstMeeting = !npc.hasInteractedWithPlayer
            
            // Find the start and end of the conditional block
            guard let startIndex = processedText.range(of: "{if:first_meeting}"),
                  let elseIndex = processedText.range(of: "{else}"),
                  let endIndex = processedText.range(of: "{endif}") else {
                return processedText // Return original text if tags are malformed
            }
            
            // Extract the text blocks
            let firstMeetingText = String(processedText[startIndex.upperBound..<elseIndex.lowerBound])
            let subsequentText = String(processedText[elseIndex.upperBound..<endIndex.lowerBound])
            
            // Replace the entire conditional block with the appropriate text
            let conditionalBlock = String(processedText[startIndex.lowerBound..<endIndex.upperBound])
            processedText = processedText.replacingOccurrences(
                of: conditionalBlock,
                with: isFirstMeeting ? firstMeetingText : subsequentText
            )
        }
        
        // Handle player name replacement
        if processedText.contains("{player_name}") {
            processedText = processedText.replacingOccurrences(
                of: "{player_name}",
                with: player.name
            )
        }
        
        return processedText
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
   
        tree = mergeGossipNodes(into: tree)
        
        if !npc.isIntimidated {
            tree = mergeDesiredVictimNodes(into: tree)
        }
        
        // Add fake alibi options if player has the UnholyTongue ability (Silver Tongue)
        if AbilitiesSystem.shared.hasBribe && !npc.isIntimidated {
            tree = mergeFakeAlibiNodes(into: tree)
        }
        
        // Add options to intimidate NPCs to overlook activities if player has Mysterious Person
        if AbilitiesSystem.shared.hasMysteriousPerson && !npc.isIntimidated {
            tree = mergeOverlookActivitiesNodes(into: tree)
        }
        
        // Store the complete tree
        self.dialogueTree = tree
        
        // Get initial node
        let initialNodeId = tree.initialNode
        if let node = tree.nodes[initialNodeId] {
            currentNode = node
            let processedText = processConditionalText(node.text)
            return (processedText, filterAvailableOptions(options: node.options))
        }
        
        return nil
    }
    
    private func mergeDesiredVictimNodes(into baseTree: DialogueTree) -> DialogueTree {
        var nodes = baseTree.nodes
        
        guard let desiredVictim = GameStateService.shared.player?.desiredVictim else { return baseTree }
        
        // Create unique node IDs for our desiredVictim dialogue flow
        let askAboutVictimNodeId = "ask_about_desired_victim"
        let bribeSuccessNodeId = "bribe_success_victim_info"
        let bribeFailNodeId = "bribe_fail_victim_info"
        let bribeAttemptFailNodeId = "bribe_attempt_fail"
        let noMatchingNPCsNodeId = "no_matching_npcs"
        let offerPaymentNodeId = "offer_payment_for_info"
        
        // Get all runtime NPCs to search for matching victims
        let allNPCs = NPCReader.getNPCs()
        
        // Filter NPCs that match the desired victim criteria
        let matchingNPCs = allNPCs.filter { desiredVictim.isDesiredVictim(npc: $0) && $0.id != npc.id }
        
        // Craft the desired victim description based on available criteria
        let victimDescription = desiredVictim.getDescription()
        
        // Create the initial asking node
        let askingText = "I'm looking for someone. \(victimDescription.isEmpty ? "Someone special." : "Specifically, someone who is \(victimDescription).")"
        
        // First node is the player asking about someone
        let askAboutVictimNode = DialogueNode(
            text: "Looking for someone, are you? Why do you want to find such a person?",
            options: [
                DialogueNodeOption(
                    from: "I need to speak with them on an important matter. [Persuasion]",
                    to: offerPaymentNodeId,
                    type: .persuasion,
                    failureNode: bribeAttemptFailNodeId,
                    failureActions: [
                        DialogueAction.modifyStat(target: .npc, stat: .relationship, value: -5),
                        DialogueAction.modifyStat(target: .global, stat: .awareness, value: 10)
                    ]
                ),
                DialogueNodeOption(
                    from: "I have my reasons. Perhaps we could make a deal? [Persuasion]",
                    to: offerPaymentNodeId,
                    type: .persuasion,
                    failureNode: bribeAttemptFailNodeId,
                    failureActions: [
                        DialogueAction.modifyStat(target: .npc, stat: .relationship, value: -5),
                        DialogueAction.modifyStat(target: .global, stat: .awareness, value: 10)
                    ]
                ),
                DialogueNodeOption(
                    from: "Never mind, it's not important.",
                    to: baseTree.initialNode,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[askAboutVictimNodeId] = askAboutVictimNode
        
        // Node for successful persuasion, offering payment
        let offerPaymentNode = DialogueNode(
            text: "I might know something about who you're looking for... For 100 coins, I could tell you what I know.",
            options: [
                DialogueNodeOption(
                    from: "Here's 100 coins. Tell me what you know. [100 coins]",
                    to: matchingNPCs.isEmpty ? noMatchingNPCsNodeId : bribeSuccessNodeId,
                    type: .normal,
                    requirements: DialogueRequirements(isNight: nil, isIndoor: nil, coins: 100, minRelationship: nil, maxRelationship: nil),
                    successActions: [
                        DialogueAction.modifyStat(target: .player, stat: .coins, value: -100)
                    ]
                ),
                DialogueNodeOption(
                    from: "On second thought, that's too much.",
                    to: bribeFailNodeId,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[offerPaymentNodeId] = offerPaymentNode
        
        // Create the bribe failure node (when player refuses to pay)
        let bribeFailNode = DialogueNode(
            text: "Then I'm afraid I can't help you. My knowledge has a price.",
            options: [
                DialogueNodeOption(
                    from: "I understand.",
                    to: baseTree.initialNode,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[bribeFailNodeId] = bribeFailNode
        
        // Create the bribe attempt failure node (when player's persuasion fails)
        let bribeAttemptFailNode = DialogueNode(
            text: "Are you trying to bribe me? I should report you to the guards for such an insulting proposition. Do you think I'm some common informant to be bought with a handful of coins?",
            options: [
                DialogueNodeOption(
                    from: "It was just a misunderstanding.",
                    to: "end",
                    type: .normal
                ),
                DialogueNodeOption(
                    from: "My apologies, I meant no offense.",
                    to: "end",
                    type: .normal
                ),
                DialogueNodeOption(
                    from: "Forget I asked.",
                    to: "end",
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[bribeAttemptFailNodeId] = bribeAttemptFailNode
        
        // Special node for when there are no matching NPCs
        let noMatchingNPCsNode = DialogueNode(
            text: "I appreciate the coin, but after thinking about it... I don't know anyone matching that description. So, you could take your money back. Perhaps someone your are looking fore not from around here, or I simply haven't crossed paths with them.",
            options: [
                DialogueNodeOption(
                    from: "Thanks anyway.",
                    to: "end",
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[noMatchingNPCsNodeId] = noMatchingNPCsNode
        
        // Create the bribe success node with information about potential victims (only if there are matching NPCs)
        if !matchingNPCs.isEmpty {
            // Select a random matching NPC to provide information about
            if let selectedNPC = matchingNPCs.randomElement() {
                var bribeSuccessText = "Let me think... Ah, yes."
                
                // Get the location information for this NPC
                if let location = LocationReader.getLocationById(by: selectedNPC.currentLocationId) {
                    bribeSuccessText += " I know exactly who you're looking for. \(selectedNPC.name), \(selectedNPC.sex == .male ? "he" : "she")'s a \(selectedNPC.profession.rawValue). You can find \(selectedNPC.sex == .male ? "him" : "her") at \(location.name)."
                    
                    // Add information about when they're typically there if applicable
                    let timeInfo = selectedNPC.homeLocationId == selectedNPC.currentLocationId 
                        ? " That's where \(selectedNPC.sex == .male ? "he" : "she") lives, so you might find \(selectedNPC.sex == .male ? "him" : "her") there most times."
                        : " \(selectedNPC.sex == .male ? "He" : "She") usually goes there during the day."
                    
                    bribeSuccessText += timeInfo
                    
                    // Add a hint about the NPC if possible
                    if selectedNPC.morality == .chaoticEvil {
                        bribeSuccessText += " Be careful though, \(selectedNPC.sex == .male ? "he" : "she") has a dark reputation."
                    } else if selectedNPC.morality == .chaoticGood {
                        bribeSuccessText += " \(selectedNPC.sex == .male ? "He's" : "She's") well-respected around here."
                    }
                } else {
                    bribeSuccessText += " There's someone matching that description, but I'm not sure where to find them right now."
                }
                
                // Create the success node with the information
                let bribeSuccessNode = DialogueNode(
                    text: bribeSuccessText,
                    options: [
                        DialogueNodeOption(
                            from: "Thank you for the information.",
                            to: "end",
                            type: .normal
                        )
                    ],
                    requirements: nil
                )
                
                // Add the bribe success node
                nodes[bribeSuccessNodeId] = bribeSuccessNode
            }
        }
        
        // Add the option to ask about desired victims to all relevant nodes
        for (nodeId, node) in nodes {
            if nodeId == baseTree.initialNode {
                var options = node.options
                options.append(DialogueNodeOption(
                    from: askingText,
                    to: askAboutVictimNodeId,
                    type: .normal
                ))
                nodes[nodeId] = DialogueNode(text: node.text, options: options, requirements: node.requirements)
            }
        }
        
        return DialogueTree(initialNode: baseTree.initialNode, nodes: nodes)
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
            if nodeId == baseTree.initialNode {
                var options = node.options
                options.append(DialogueNodeOption(
                    from: "What's new in town?",
                    to: "gossip_0",
                    type: .normal,
                    requirements: DialogueRequirements(isNight: nil, isIndoor: nil, coins: nil, minRelationship: 2, maxRelationship: nil)
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
              let node = tree.nodes[nodeId] else {
            DebugLogService.shared.log("Error: Could not find node with ID: \(nodeId). Ending dialogue.", category: "Error")
            return nil
        }
        
        currentNode = node
        currentNodeId = nodeId
        let processedText = processConditionalText(node.text)
        return (processedText, filterAvailableOptions(options: node.options))
    }
    
    func normalizeRelationshipNode(_ nodeText: String) {
        guard let options = currentNode?.options else { return }
        
        for optionInLoop in options {
            if optionInLoop.text == nodeText && (optionInLoop.type == .relationshipIncrease || optionInLoop.type == .relationshipDecrease) {
                optionInLoop.type = .normal
            }
        }
    }
    
    // Example method: attempt a persuasion check against an NPC
    func attemptPersuasion(npc: NPC) -> Bool {
        let successChance = calculatePersuasionSuccessChance(for: npc)
        let roll = Int.random(in: 1...100)
        
        return roll <= successChance
    }
    
    // Calculate persuasion success chance based on various factors
    // Renamed from calculateIntimidationSuccessChance, logic was already updated for persuasion
    private func calculatePersuasionSuccessChance(for npc: NPC) -> Int {
        var baseChance = 50 // Base chance for persuasion
        
        // Relationship with player influence
        let relationshipEffect = npc.playerRelationship.value / 2 // Positive relationship helps
        baseChance += relationshipEffect
        
        // Influence of UnholyTongue ability
        if AbilitiesSystem.shared.hasUnholyTongue {
            baseChance += 20 // UnholyTongue increases success chance by 20%
        }
        
        // Player skills (Placeholder - needs actual skill system integration)
        // Example: if player.skills.persuasion > npc.resistance.persuasion { baseChance += 15 }
        
        // Ensure chance is within 0-100%
        return max(0, min(100, baseChance))
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
        
        // Check if player has enough coins for this option
        if let requiredCoins = req.coins,
           let player = gameStateService.player,
           player.coins.value < requiredCoins {
            return false
        }
        
        return true
    }
    
    private func filterAvailableOptions(options: [DialogueNodeOption]) -> [DialogueNodeOption] {
        return options.filter(meetsRequirements)
    }
    
    func mergeFakeAlibiNodes(into baseTree: DialogueTree) -> DialogueTree {
        guard let alibiTree = dialogueSystem.getFakeAlibiDialogueTree() else {
            DebugLogService.shared.log("Fake Alibi dialogue tree not found. Skipping merge.", category: "DialogueProcessor")
            return baseTree
        }

        // 1. Merge and resolve nodes from the alibi subtree
        var mergedNodes = mergeAndResolveSubTreeNodes(subTree: alibiTree, 
                                                    baseTreeInitialNodeId: baseTree.initialNode, 
                                                    into: baseTree.nodes)

        // 2. Define the entry point option
        let entryOption = DialogueNodeOption(
            from: "I need to discuss a private matter... [Silver Tongue]", // TODO: Consider making this text a constant
            to: alibiTree.initialNode, // Points to the start of the alibi tree
            type: .normal, 
            requirements: nil // TODO: Add requirement for Silver Tongue ability if needed
        )

        // 3. Add the entry point option to the base tree's initial node
        mergedNodes = addEntryPointOption(to: mergedNodes, 
                                        baseTreeInitialNodeId: baseTree.initialNode, 
                                        entryOption: entryOption)
        
        return DialogueTree(initialNode: baseTree.initialNode, nodes: mergedNodes)
    }
    
    func mergeOverlookActivitiesNodes(into baseTree: DialogueTree) -> DialogueTree {
        guard let overlookTree = dialogueSystem.getOverlookActivitiesDialogueTree() else {
            DebugLogService.shared.log("Overlook Activities dialogue tree not found. Skipping merge.", category: "DialogueProcessor")
            return baseTree
        }

        // 1. Merge and resolve nodes from the overlook subtree
        var mergedNodes = mergeAndResolveSubTreeNodes(subTree: overlookTree, 
                                                    baseTreeInitialNodeId: baseTree.initialNode, 
                                                    into: baseTree.nodes)

        // 2. Define the entry point option
        let entryOption = DialogueNodeOption(
            from: "Actually, I've been meaning to speak with you about something concerning... [Mysterious Person]", // TODO: Consider making this text a constant
            to: overlookTree.initialNode, // Points to the start of the overlook tree
            type: .normal, 
            requirements: nil // TODO: Add requirement for Mysterious Person ability if needed
        )

        // 3. Add the entry point option to the base tree's initial node
        mergedNodes = addEntryPointOption(to: mergedNodes, 
                                        baseTreeInitialNodeId: baseTree.initialNode, 
                                        entryOption: entryOption)
        
        return DialogueTree(initialNode: baseTree.initialNode, nodes: mergedNodes)
    }
    
    // Method removed, replaced by loadSpecificDialogue
    // func loadCasualtySuspicionDialogue() -> (text: String, options: [DialogueNodeOption])? { ... }

    // <<< Added new method to load by filename >>>
    func loadSpecificDialogue(filename: String) -> (text: String, options: [DialogueNodeOption])? {
        DebugLogService.shared.log("Attempting to load specific dialogue: \(filename)", category: "DialogueProcessor")
        // Try to get the specific dialogue tree by filename
        if let specificTree = dialogueSystem.getDialogueTree(byFilename: filename) {
            // Store the tree for future reference
            self.dialogueTree = specificTree
            
            // Get initial node
            let initialNodeId = specificTree.initialNode
            if let node = specificTree.nodes[initialNodeId] {
                currentNode = node
                currentNodeId = initialNodeId
                let processedText = processConditionalText(node.text)
                DebugLogService.shared.log("Successfully loaded specific dialogue: \(filename)", category: "DialogueProcessor")
                return (processedText, filterAvailableOptions(options: node.options))
            }
             DebugLogService.shared.log("Error: Initial node '\(initialNodeId)' not found in \(filename)", category: "Error")
        } else {
             DebugLogService.shared.log("Error: Dialogue tree not found for filename: \(filename)", category: "Error")
        }
        
        return nil // Return nil if loading failed
    }

    // <<< New Helper Function >>>
    private func mergeAndResolveSubTreeNodes(subTree: DialogueTree, baseTreeInitialNodeId: String, into nodes: [String: DialogueNode]) -> [String: DialogueNode] {
        var mergedNodes = nodes

        for (nodeId, node) in subTree.nodes {
            let resolvedOptions = node.options.map { option -> DialogueNodeOption in
                var nextNodeTarget = option.nextNode
                if option.nextNode == DialogueProcessor.returnToMainPlaceholder {
                    nextNodeTarget = baseTreeInitialNodeId
                } else if option.nextNode == DialogueProcessor.proceedToEndPlaceholder {
                    nextNodeTarget = "end" 
                }
                // Create a new instance, ensuring ALL relevant fields are passed
                return DialogueNodeOption(from: option.text, 
                                          to: nextNodeTarget, 
                                          type: option.type, 
                                          requirements: option.requirements,
                                          failureNode: option.failureNode,
                                          successActions: option.successActions, // <<< Pass successActions
                                          failureActions: option.failureActions) // <<< Pass failureActions
            }
            mergedNodes[nodeId] = DialogueNode(text: node.text, options: resolvedOptions, requirements: node.requirements)
        }
        return mergedNodes
    }

    // <<< New Helper Function >>>
    private func addEntryPointOption(to nodes: [String: DialogueNode], baseTreeInitialNodeId: String, entryOption: DialogueNodeOption) -> [String: DialogueNode] {
        var updatedNodes = nodes
        // Add the option to the specified entry point(s) in the base tree
        // Currently targets only the initial node of the base tree.
        if let entryNode = updatedNodes[baseTreeInitialNodeId] {
            var mutableOptions = entryNode.options
            // Avoid adding duplicate entry options if the merge function is called multiple times somehow
            if !mutableOptions.contains(where: { $0.nextNode == entryOption.nextNode && $0.text == entryOption.text }) {
                mutableOptions.append(entryOption)
                updatedNodes[baseTreeInitialNodeId] = DialogueNode(text: entryNode.text, options: mutableOptions, requirements: entryNode.requirements)
            }
        } else {
            DebugLogService.shared.log("Initial node \(baseTreeInitialNodeId) of baseTree not found for adding entry point option: \(entryOption.text)", category: "DialogueProcessor")
        }
        return updatedNodes
    }
}
