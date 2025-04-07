import Foundation

class NPCReader : GameService {
    private static var npcs: [[String: Any]] = []
    
    static func loadNPCs() {
        if npcs.isEmpty {
            if let url = Bundle.main.url(forResource: "NPCs", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let loadedNPCs = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                npcs = loadedNPCs
            }
        }
    }
    
    static func getNPCs() -> [NPC] {
        loadNPCs()
        
        do {
            let convertedNPCs = npcs.compactMap { createNPC(from: $0) }
            
            var index = 0
            for npc in convertedNPCs {
                npc.index = index
                index += 1
            }
            DebugLogService.shared.log("getNPCs returning \(convertedNPCs.count) NPCs", category: "NPC")
            return convertedNPCs
        } catch {
            DebugLogService.shared.log("Error reading NPCs.json file: \(error)", category: "NPC")
        }
    }

    static func getNPC(by id: UUID) -> NPC? {
        loadNPCs()
        
        guard let npcData = npcs.first(where: { ($0["id"] as? String).flatMap(UUID.init) == id }) else {
            return nil
        }
        
        return createNPC(from: npcData)
    }
    
    static func getRandomNPCs(count: Int) -> [NPC] {
        loadNPCs()
        
        let shuffledNPCs = npcs.shuffled()
        return shuffledNPCs.prefix(count).compactMap { createNPC(from: $0) }
    }
    
    private static func createNPC(from data: [String: Any]) -> NPC? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let age = data["age"] as? Int,
              let sexString = data["sex"] as? String,
              let professionString = data["profession"] as? String,
              let isVampire = data["isVampire"] as? Bool else {
            DebugLogService.shared.log("Failed to parse NPC data: \(data)", category: "Error")
            return nil
        }
        
        let sex: Sex = sexString.lowercased() == "male" ? .male : .female
        
        // Map profession strings to our Profession enum by exact match
        let profession: Profession
        switch professionString {
        case Profession.blacksmith.rawValue:
            profession = .blacksmith
        case Profession.miller.rawValue:
            profession = .miller
        case Profession.cooper.rawValue:
            profession = .cooper
        case Profession.chandler.rawValue:
            profession = .chandler
        case Profession.priest.rawValue:
            profession = .priest
        case Profession.bowyer.rawValue:
            profession = .bowyer
        case Profession.armorer.rawValue:
            profession = .armorer
        case Profession.merchant.rawValue:
            profession = .merchant
        case Profession.carpenter.rawValue:
            profession = .carpenter
        case Profession.thatcher.rawValue:
            profession = .thatcher
        case Profession.tanner.rawValue:
            profession = .tanner
        case Profession.weaver.rawValue:
            profession = .weaver
        case Profession.hunter.rawValue:
            profession = .hunter
        case Profession.tailor.rawValue:
            profession = .tailor
        case Profession.baker.rawValue:
            profession = .baker
        case Profession.butcher.rawValue:
            profession = .butcher
        case Profession.brewer.rawValue:
            profession = .brewer
        case Profession.apothecary.rawValue:
            profession = .apothecary
        case Profession.scribe.rawValue:
            profession = .scribe
        case Profession.herald.rawValue:
            profession = .herald
        case Profession.minstrel.rawValue:
            profession = .minstrel
        case Profession.guardman.rawValue, "Guardman":
            profession = .guardman
        case Profession.alchemist.rawValue:
            profession = .alchemist
        case Profession.farrier.rawValue:
            profession = .farrier
        case Profession.innkeeper.rawValue, "Innkeeper": // Handle common misspelling in JSON
            profession = .innkeeper
        case Profession.adventurer.rawValue:
            profession = .adventurer
        case Profession.wenche.rawValue:
            profession = .wenche
        case Profession.general.rawValue:
            profession = .general
        default:
            DebugLogService.shared.log("Unknown profession '\(professionString)', defaulting to adventurer", category: "Warning")
            profession = .adventurer
        }
        
        return NPC(name: name, sex: sex, age: age, profession: profession, isVampire: isVampire, id: id)
    }
} 
