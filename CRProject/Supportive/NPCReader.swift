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
            return nil
        }
        
        let sex: Sex = sexString.lowercased() == "male" ? .male : .female
        let profession = Profession(rawValue: professionString) ?? .adventurer
        
        return NPC(name: name, sex: sex, age: age, profession: profession, isVampire: isVampire, id: id)
    }
} 
