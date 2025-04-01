import Foundation

// MARK: - Dialogue System
class DialogueSystem {
    private var professionDialogues: [String: DialogueTree] = [:]
    private var generalDialogues: DialogueTree?
    
    static func load() -> DialogueSystem {
        let system = DialogueSystem()
        system.loadDialogues()
        return system
    }
    
    private func loadDialogues() {
        if let url = Bundle.main.url(forResource: "ProfessionDialogues", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                professionDialogues = try JSONDecoder().decode([String: DialogueTree].self, from: data)
            } catch {
                print("Error loading profession dialogues: \(error)")
            }
        }
        
        if let url = Bundle.main.url(forResource: "GeneralDialogues", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                generalDialogues = try JSONDecoder().decode(DialogueTree.self, from: data)
            } catch {
                print("Error loading general dialogues: \(error)")
            }
        }
    }
    
    func getDialogueTree(for profession: String) -> DialogueTree? {
        // First try exact match
        if let tree = professionDialogues[profession] {
            return tree
        }
        
        // Try matching without parenthetical descriptions
        let normalizedProfession = profession.split(separator: "(").first?.trimmingCharacters(in: .whitespaces) ?? profession
        if let tree = professionDialogues[normalizedProfession] {
            return tree
        }
        
        // If still not found and not already trying general dialogue, return general dialogue
        if profession != Profession.general.rawValue {
            print("No specific dialogue found for \(profession), falling back to general dialogue")
            return getGeneralDialogueTree()
        }
        
        return nil
    }
    
    func getGeneralDialogueTree() -> DialogueTree? {
        return generalDialogues
    }
}

// MARK: - Dialogue Tree
struct DialogueTree: Codable {
    let initialNode: String
    let nodes: [String: DialogueNode]
}

struct DialogueNode: Codable {
    let text: String
    let options: [DialogueNodeOption]
    let requirements: DialogueRequirements?
}

struct DialogueNodeOption: Codable {
    let text: String
    let type: DialogueOptionType
    let nextNode: String
    let requirements: DialogueRequirements?
}

struct DialogueRequirements: Codable {
    let minCharisma: Int?
    let minStrength: Int?
    let isNight: Bool?
    let isIndoor: Bool?
}

enum DialogueOptionType: String, Codable {
    case normal
    case intimidate
    case seduce
}