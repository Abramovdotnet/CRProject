import Foundation

// MARK: - Dialogue System
class DialogueSystem {
    private var professionDialogues: [String: DialogueTree] = [:]
    private var generalDialogues: DialogueTree?
    private var uniqueDialogues: [Int: DialogueTree] = [:]
    
    static func load() -> DialogueSystem {
        let system = DialogueSystem()
        system.loadDialogues()
        return system
    }
    
    private func loadDialogues() {
        // Load profession dialogues
        if let url = Bundle.main.url(forResource: "ProfessionDialogues", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                professionDialogues = try JSONDecoder().decode([String: DialogueTree].self, from: data)
                DebugLogService.shared.log("Successfully loaded profession dialogues", category: "Dialogue")
            } catch {
                DebugLogService.shared.log("Error loading profession dialogues: \(error)", category: "Error")
            }
        } else {
            DebugLogService.shared.log("Could not find ProfessionDialogues.json", category: "Error")
        }
        
        // Load general dialogues
        if let url = Bundle.main.url(forResource: "GeneralDialogues", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                generalDialogues = try JSONDecoder().decode(DialogueTree.self, from: data)
                DebugLogService.shared.log("Successfully loaded general dialogues", category: "Dialogue")
            } catch {
                DebugLogService.shared.log("Error loading general dialogues: \(error)", category: "Error")
            }
        } else {
            DebugLogService.shared.log("Could not find GeneralDialogues.json", category: "Error")
        }
        
        // Load unique dialogues - using the same pattern as profession dialogues
        // We'll load them on demand when getDialogueTree is called
    }
    
    func getDialogueTree(for profession: String, player: Player, npcId: Int? = nil) -> DialogueTree? {
        // First check for unique dialogue
        if let npcId = npcId {
            DebugLogService.shared.log("Checking for unique dialogue for NPC \(npcId)", category: "Dialogue")
            let uniqueDialogueFileName = "Dialogue\(npcId)"
            if let url = Bundle.main.url(forResource: uniqueDialogueFileName, withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                do {
                    let uniqueTree = try JSONDecoder().decode(DialogueTree.self, from: data)
                    DebugLogService.shared.log("Successfully loaded unique dialogue for NPC \(npcId)", category: "Dialogue")
                    normalizeProcessedRelationshipNodes(player: player, tree: uniqueTree)
                    return uniqueTree
                } catch {
                    DebugLogService.shared.log("Error loading unique dialogue for NPC \(npcId): \(error)", category: "Error")
                }
            }
        }
        
        // Then try profession dialogues
        if let tree = professionDialogues[profession] {
            normalizeProcessedRelationshipNodes(player: player, tree: tree)
            return tree
        }
        
        // Try matching without parenthetical descriptions
        let normalizedProfession = profession.split(separator: "(").first?.trimmingCharacters(in: .whitespaces) ?? profession
        if let tree = professionDialogues[normalizedProfession] {
            normalizeProcessedRelationshipNodes(player: player, tree: tree)
            return tree
        }
        
        // If still not found and not already trying general dialogue, return general dialogue
        if profession != Profession.noProfession.rawValue {
            DebugLogService.shared.log("No specific dialogue found for \(profession), falling back to general dialogue", category: "Dialogue")
            return getGeneralDialogueTree()
        }
        
        return nil
    }
    
    func getGeneralDialogueTree() -> DialogueTree? {
        return generalDialogues
    }
    
    func normalizeProcessedRelationshipNodes(player: Player, tree: DialogueTree) {
        let relationsipNodes = tree.nodes.filter { $0.value.options.contains(where: { $0.type == .relationshipDecrease || $0.type == .relationshipIncrease}) }
        
        for node in relationsipNodes {
            for option in node.value.options {
                if player.checkIsRelationshipDialogueNodeOptionProcessed(option: option.text) {
                    option.type = .normal
                }
            }
        }
    }
}

// MARK: - Dialogue Tree
struct DialogueTree: Codable {
    let initialNode: String
    let nodes: [String: DialogueNode]
}

struct DialogueNode: Codable, Equatable {
    let text: String
    let options: [DialogueNodeOption]
    let requirements: DialogueRequirements?
    
    static func == (lhs: DialogueNode, rhs: DialogueNode) -> Bool {
        return lhs.text == rhs.text &&
               lhs.options == rhs.options &&
               lhs.requirements == rhs.requirements
    }
}

class DialogueNodeOption: Codable, Equatable {
    let text: String
    var type: DialogueOptionType
    let nextNode: String
    let requirements: DialogueRequirements?
    
    init(from text: String, to nextNode: String, type: DialogueOptionType, requirements: DialogueRequirements? = nil) {
        self.text = text
        self.type = type
        self.nextNode = nextNode
        self.requirements = requirements
    }
    
    static func == (lhs: DialogueNodeOption, rhs: DialogueNodeOption) -> Bool {
        return lhs.text == rhs.text &&
               lhs.type == rhs.type &&
               lhs.nextNode == rhs.nextNode &&
               lhs.requirements == rhs.requirements
    }
}

struct DialogueRequirements: Codable, Equatable {
    let isNight: Bool?
    let isIndoor: Bool?
    let coins: Int?
    let minRelationship: Int?
    let maxRelationship: Int?
    
    static func == (lhs: DialogueRequirements, rhs: DialogueRequirements) -> Bool {
        return lhs.isNight == rhs.isNight &&
               lhs.isIndoor == rhs.isIndoor &&
               lhs.coins == rhs.coins &&
               lhs.minRelationship == rhs.minRelationship &&
               lhs.maxRelationship == rhs.maxRelationship
    }
}


