import Foundation

// MARK: - Dialogue System
class DialogueSystem {
    private var professionDialogues: [String: DialogueTree] = [:]
    private var generalDialogues: DialogueTree?
    private var specificDialogueTrees: [String: DialogueTree] = [:]
    private var uniqueDialogues: [String: DialogueTree] = [:]
    
    static let shared = DialogueSystem()
    
    private init() {
        loadProfessionDialogues()
        loadGeneralDialogues()
        loadUniqueDialogues()
        loadSpecificDialogueTrees()
    }
    
    private func loadProfessionDialogues() {
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
    }
    
    private func loadGeneralDialogues() {
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
    }
    
    private func loadUniqueDialogues() {
        // Load unique dialogues - using the same pattern as profession dialogues
        // We'll load them on demand when getDialogueTree is called
    }
    
    private func loadSpecificDialogueTrees() {
        // Список всех специфичных диалогов (включая квестовые)
        let specificDialogueFilenames = [
            "CasualtySuspicionDialogue", 
            "fakeAlibiNodes", 
            "overlookActivitiesNodes",
            "Quest_PrisonGuard_Start",
            "Quest_PrisonGuard_RecruitMerc",
            "Quest_PrisonGuard_Complete",
            "Quest_Earrings_Start",
            "Quest_Earrings_Gambler",
            "Quest_Earrings_Priest",
            "Quest_Earrings_Gambler_Return"
            // Добавлять сюда другие по мере необходимости
        ]
        
        DebugLogService.shared.log("DialogueSystem: Loading specific dialogue trees...", category: "DialogueLoading")
        var loadedCount = 0
        for fileName in specificDialogueFilenames {
            // loadDialogueTree ожидает имя файла без .json
            if let tree = loadDialogueTree(fromFile: fileName) {
                // Сохраняем в словарь с полным именем файла как ключ
                let fullFilename = fileName + ".json"
                specificDialogueTrees[fullFilename] = tree
                // DebugLogService.shared.log("DialogueSystem: Successfully loaded and stored specific dialogue: \(fullFilename)", category: "DialogueLoading") // Лог уже есть в loadDialogueTree
                loadedCount += 1
            } else {
                 DebugLogService.shared.log("DialogueSystem Warning: Failed to load specific dialogue file: \(fileName).json", category: "DialogueLoading")
            }
        }
         DebugLogService.shared.log("DialogueSystem: Finished loading specific dialogues. Total loaded: \(loadedCount) out of \(specificDialogueFilenames.count) listed.", category: "DialogueLoading")
    }
    
    private func loadDialogueTree(fromFile fileName: String) -> DialogueTree? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            DebugLogService.shared.log("Error: Could not find or load \(fileName).json", category: "Error")
            return nil
        }
        do {
            let dialogueTree = try JSONDecoder().decode(DialogueTree.self, from: data)
            DebugLogService.shared.log("Successfully loaded \(fileName).json", category: "DialogueLoading")
            return dialogueTree
        } catch {
            DebugLogService.shared.log("Error decoding \(fileName).json: \(error)", category: "Error")
            return nil
        }
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
    
    func getDialogueTree(byFilename filename: String) -> DialogueTree? {
        return specificDialogueTrees[filename]
    }
    
    func getFakeAlibiDialogueTree() -> DialogueTree? {
        return specificDialogueTrees["fakeAlibiNodes.json"]
    }
    
    func getOverlookActivitiesDialogueTree() -> DialogueTree? {
        return specificDialogueTrees["overlookActivitiesNodes.json"]
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
    let failureNode: String?
    let successActions: [DialogueAction]?
    let failureActions: [DialogueAction]?
    
    // Explicit CodingKeys to ensure all properties are considered by Codable
    enum CodingKeys: String, CodingKey {
        case text, type, nextNode, requirements, failureNode, successActions, failureActions
    }
    
    // Custom initializer from Decoder
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        type = try container.decode(DialogueOptionType.self, forKey: .type)
        nextNode = try container.decode(String.self, forKey: .nextNode)
        // Use decodeIfPresent for optional properties
        requirements = try container.decodeIfPresent(DialogueRequirements.self, forKey: .requirements)
        failureNode = try container.decodeIfPresent(String.self, forKey: .failureNode)
        successActions = try container.decodeIfPresent([DialogueAction].self, forKey: .successActions)
        failureActions = try container.decodeIfPresent([DialogueAction].self, forKey: .failureActions)
    }
    
    // Custom initializer for programmatic creation (already exists, ensure it matches properties)
    init(from text: String, 
         to nextNode: String, 
         type: DialogueOptionType, 
         requirements: DialogueRequirements? = nil, 
         failureNode: String? = nil, 
         successActions: [DialogueAction]? = nil,
         failureActions: [DialogueAction]? = nil) {
        self.text = text
        self.type = type
        self.nextNode = nextNode
        self.requirements = requirements
        self.failureNode = failureNode
        self.successActions = successActions
        self.failureActions = failureActions
    }
    
    // Equatable conformance (already exists)
    static func == (lhs: DialogueNodeOption, rhs: DialogueNodeOption) -> Bool {
        return lhs.text == rhs.text &&
               lhs.type == rhs.type &&
               lhs.nextNode == rhs.nextNode &&
               lhs.requirements == rhs.requirements &&
               lhs.failureNode == rhs.failureNode &&
               lhs.successActions == rhs.successActions && 
               lhs.failureActions == rhs.failureActions
    }
}

struct DialogueRequirements: Codable, Equatable {
    let isNight: Bool?
    let isIndoor: Bool?
    let coins: Int?
    let minRelationship: Int?
    let maxRelationship: Int?
    let inventoryItems: [RequiredItem]?
    
    static func == (lhs: DialogueRequirements, rhs: DialogueRequirements) -> Bool {
        return lhs.isNight == rhs.isNight &&
               lhs.isIndoor == rhs.isIndoor &&
               lhs.coins == rhs.coins &&
               lhs.minRelationship == rhs.minRelationship &&
               lhs.maxRelationship == rhs.maxRelationship &&
               lhs.inventoryItems == rhs.inventoryItems
    }
}

struct RequiredItem: Codable, Equatable {
    let itemId: Int
    let quantity: Int
}
