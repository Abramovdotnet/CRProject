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
    
    init(dialogueSystem: DialogueSystem, player: Player, npc: NPC) {
        self.dialogueSystem = dialogueSystem
        self.player = player
        self.npc = npc
        self.gameTimeService = DependencyManager.shared.resolve()
        self.gameStateService = DependencyManager.shared.resolve()
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
        
        // Calculate persuasion success chance
        let successChance = calculatePersuasionSuccessChance(for: npc)
        let successPercentage = String(format: "%d%%", successChance)
        
        // Create the initial asking node
        let askingText = "I'm looking for someone. \(victimDescription.isEmpty ? "Someone special." : "Specifically, someone who is \(victimDescription).")"
        
        // First node is the player asking about someone
        let askAboutVictimNode = DialogueNode(
            text: "Looking for someone, are you? Why do you want to find such a person?",
            options: [
                DialogueNodeOption(
                    from: "I need to speak with them on an important matter. [Persuasion: \(successPercentage)]",
                    to: offerPaymentNodeId, // This will be intercepted by ViewModel for persuasion check
                    type: .askingForDesiredVictim
                ),
                DialogueNodeOption(
                    from: "I have my reasons. Perhaps we could make a deal? [Persuasion: \(successPercentage)]",
                    to: offerPaymentNodeId, // This will be intercepted by ViewModel for persuasion check
                    type: .askingForDesiredVictim
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
                    from: "Here's 100 coins. Tell me what you know. [Pay 100 coins]",
                    to: matchingNPCs.isEmpty ? noMatchingNPCsNodeId : bribeSuccessNodeId,
                    type: .desiredVictimBribe,
                    requirements: DialogueRequirements(isNight: nil, isIndoor: nil, coins: 100, minRelationship: nil, maxRelationship: nil)
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
                    type: .relationshipDecrease
                ),
                DialogueNodeOption(
                    from: "My apologies, I meant no offense.",
                    to: "end",
                    type: .normal
                ),
                DialogueNodeOption(
                    from: "Forget I asked.",
                    to: "end",
                    type: .relationshipDecrease
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
    
    func normalizeRelationshipNode( _ nodeText: String) {
        guard let options = currentNode?.options else { return }
        
        for option in options {
            if option.text == nodeText && option.type == .relationshipIncrease || option.type == .relationshipDecrease {
                option.type = .normal
            }
        }
        
    }
    
    func attemptIntimidation(npc: NPC) -> Bool {
        let baseChance = 50
        
        let finalChance = baseChance - (AbilitiesSystem.shared.hasUnholyTongue ? 20 : 0 - npc.playerRelationship.value)
        return Int.random(in: 1...100) >= finalChance
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
    
    /// Calculates the persuasion success chance based on player-NPC relationship and other factors
    func calculatePersuasionSuccessChance(for npc: NPC) -> Int {
        // Base chance
        let baseChance = 50
        
        // Bonus from relationship (up to +10)
        let relationshipBonus = npc.playerRelationship.value
        
        // Bonus from Unholy Tongue ability (+20)
        let unholyTongueBonus = AbilitiesSystem.shared.hasUnholyTongue ? 20 : 0
        
        // Calculate final chance (capped at 90%)
        let finalChance = min(90, baseChance + relationshipBonus + unholyTongueBonus)
        
        return finalChance
    }
    
    /// Checks if a persuasion attempt is successful based on calculated chance
    func attemptPersuasion(with npc: NPC) -> Bool {
        let successChance = calculatePersuasionSuccessChance(for: npc)
        let roll = Int.random(in: 1...100)
        return roll <= successChance
    }
    
    func mergeFakeAlibiNodes(into baseTree: DialogueTree) -> DialogueTree {
        var nodes = baseTree.nodes
        
        // Create unique node IDs for this dialogue path
        let askForAlibiNodeId = "ask_for_alibi"
        let alibiResponseNodeId = "alibi_response"
        let alibiSuccessNodeId = "alibi_success"
        let alibiRefuseNodeId = "alibi_refuse"
        
        // Create the node for player asking about providing an alibi
        let askForAlibiNode = DialogueNode(
            text: "I need someone who can vouch for my whereabouts last night. Could you help me?",
            options: [
                DialogueNodeOption(
                    from: "I'd like you to provide an alibi for me. I can pay 150 coins. [Pay 150 coins]",
                    to: alibiResponseNodeId,
                    type: .fakeAlibiesBribe,
                    requirements: DialogueRequirements(isNight: nil, isIndoor: nil, coins: 150, minRelationship: nil, maxRelationship: nil)
                ),
                DialogueNodeOption(
                    from: "Never mind, it's not important.",
                    to: baseTree.initialNode,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[askForAlibiNodeId] = askForAlibiNode
        
        // Create the node for NPC response - depends on relationship
        let alibiResponseNode = DialogueNode(
            text: "You want me to lie about where you were? Well... for 150 coins, I suppose I could say you were with me.",
            options: [
                DialogueNodeOption(
                    from: "Remember, I was with you all evening.",
                    to: alibiSuccessNodeId,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[alibiResponseNodeId] = alibiResponseNode
        
        // Create the node for player refusing to proceed
        let alibiRefuseNode = DialogueNode(
            text: "Changed your mind? Probably for the best. I'm not sure I'd be very convincing anyway.",
            options: [
                DialogueNodeOption(
                    from: "Let's talk about something else.",
                    to: baseTree.initialNode,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[alibiRefuseNodeId] = alibiRefuseNode
        
        // Create the node for successful alibi arrangement
        let alibiSuccessNode = DialogueNode(
            text: "Of course I remember! We spent the entire evening together. If anyone asks, I'll make sure they know you couldn't possibly have been involved in... whatever happened.",
            options: [
                DialogueNodeOption(
                    from: "Thank you for your help.",
                    to: "end",
                    type: .normal
                ),
                DialogueNodeOption(
                    from: "I appreciate your discretion.",
                    to: "end",
                    type: .relationshipIncrease
                )
            ],
            requirements: nil
        )
        nodes[alibiSuccessNodeId] = alibiSuccessNode
        
        // Add the option to ask for alibi to the main greeting node
        for (nodeId, node) in nodes {
            if nodeId == baseTree.initialNode {
                var options = node.options
                options.append(DialogueNodeOption(
                    from: "I need to discuss a private matter... [Silver Tongue]",
                    to: askForAlibiNodeId,
                    type: .normal
                ))
                nodes[nodeId] = DialogueNode(text: node.text, options: options, requirements: node.requirements)
            }
        }
        
        return DialogueTree(initialNode: baseTree.initialNode, nodes: nodes)
    }
    
    func mergeOverlookActivitiesNodes(into baseTree: DialogueTree) -> DialogueTree {
        var nodes = baseTree.nodes
        
        // Create unique node IDs for this dialogue path
        let suspiciousActivityNodeId = "suspicious_activity"
        let intimidateOverlookNodeId = "intimidate_overlook"
        let overlookSuccessNodeId = "overlook_success"
        let overlookFailNodeId = "overlook_fail"
        
        // Calculate intimidation success chance
        let successPercentage = 50 + (AbilitiesSystem.shared.hasUnholyTongue ? 20 : 0) + npc.playerRelationship.value
        
        // Create the node for NPC noticing suspicious activity
        let suspiciousActivityNode = DialogueNode(
            text: "I've been hearing strange things about you lately. Some say you're involved in... questionable activities.",
            options: [
                DialogueNodeOption(
                    from: "Perhaps we could come to an arrangement for you to forget what you've heard. [Intimidation: \(successPercentage)]",
                    to: intimidateOverlookNodeId,
                    type: .overlookActivitiesIntimidation
                ),
                DialogueNodeOption(
                    from: "I don't know what you're talking about.",
                    to: baseTree.initialNode,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[suspiciousActivityNodeId] = suspiciousActivityNode
        
        // Create the node for intimidating the NPC to overlook
        let intimidateOverlookNode = DialogueNode(
            text: "Are you threatening me? I... I could report you to the authorities.",
            options: [
                DialogueNodeOption(
                    from: "I'm just suggesting that some things are better left alone. For everyone's sake.",
                    to: overlookSuccessNodeId,
                    type: .overlookActivitiesIntimidation
                ),
                DialogueNodeOption(
                    from: "Do what you must. I have nothing to hide.",
                    to: overlookFailNodeId,
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[intimidateOverlookNodeId] = intimidateOverlookNode
        
        // Create the node for successful intimidation
        let overlookSuccessNode = DialogueNode(
            text: "Fine. I'll... I'll keep what I've heard to myself. Just leave me alone.",
            options: [
                DialogueNodeOption(
                    from: "A wise decision.",
                    to: "end", 
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[overlookSuccessNodeId] = overlookSuccessNode
        
        // Create the node for failed intimidation
        let overlookFailNode = DialogueNode(
            text: "I won't be intimidated. People should know what kind of person you really are.",
            options: [
                DialogueNodeOption(
                    from: "You'll regret this.",
                    to: "end",
                    type: .relationshipDecrease
                ),
                DialogueNodeOption(
                    from: "Do what you must.",
                    to: "end",
                    type: .normal
                )
            ],
            requirements: nil
        )
        nodes[overlookFailNodeId] = overlookFailNode
        
        // Add the option for NPC to mention suspicious activity to the main greeting node
        for (nodeId, node) in nodes {
            if nodeId == baseTree.initialNode {
                var options = node.options
                options.append(DialogueNodeOption(
                    from: "Actually, I've been meaning to speak with you about something concerning... [Mysterious Person]",
                    to: suspiciousActivityNodeId,
                    type: .normal
                ))
                nodes[nodeId] = DialogueNode(text: node.text, options: options, requirements: node.requirements)
            }
        }
        
        return DialogueTree(initialNode: baseTree.initialNode, nodes: nodes)
    }
}
