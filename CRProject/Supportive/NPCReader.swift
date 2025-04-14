import Foundation

class NPCReader : GameService {
    private static var npcs: [[String: Any]] = []
    private static var npcsPool: [NPC] = []
    
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
        
        if npcsPool.count > 0 {
            return npcsPool
        }
        do {
            let convertedNPCs = npcs.compactMap { createNPC(from: $0) }
            
            var index = 0
            for npc in convertedNPCs {
                npc.index = index
                index += 1
            }
            DebugLogService.shared.log("getNPCs returning \(convertedNPCs.count) NPCs", category: "NPC")
            
            npcsPool = convertedNPCs
            return npcsPool
        } catch {
            DebugLogService.shared.log("Error reading NPCs.json file: \(error)", category: "NPC")
        }
    }
    
    static func getRuntimeNPC(by id: Int) -> NPC? {
        return npcsPool.first(where: { $0.id == id })
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
        guard let id = data["id"] as? Int,
              let name = data["name"] as? String,
              let age = data["age"] as? Int,
              let homeLocationId = data["homeLocationId"] as? Int,
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
        case Profession.priest.rawValue:
            profession = .priest
        case Profession.merchant.rawValue:
            profession = .merchant
        case Profession.carpenter.rawValue:
            profession = .carpenter
        case Profession.tailor.rawValue:
            profession = .tailor
        case Profession.guardman.rawValue, "Guardman":
            profession = .guardman
        case Profession.alchemist.rawValue:
            profession = .alchemist
        case Profession.adventurer.rawValue:
            profession = .adventurer
        case Profession.cityGuard.rawValue:
            profession = .cityGuard
        case Profession.gardener.rawValue:
            profession = .gardener
        case Profession.maintenanceWorker.rawValue:
            profession = .maintenanceWorker
        case Profession.cleaner.rawValue:
            profession = .cleaner
        case Profession.apprentice.rawValue:
            profession = .apprentice
        case Profession.lordLady.rawValue:
            profession = .lordLady
        case Profession.administrator.rawValue:
            profession = .administrator
        case Profession.stableHand.rawValue:
            profession = .stableHand
        case Profession.kitchenStaff.rawValue:
            profession = .kitchenStaff
        case Profession.militaryOfficer.rawValue:
            profession = .militaryOfficer
        case Profession.servant.rawValue:
            profession = .servant
        case Profession.monk.rawValue:
            profession = .monk
        case Profession.religiousScholar.rawValue:
            profession = .religiousScholar
        case Profession.generalLaborer.rawValue:
            profession = .generalLaborer
        case Profession.bookseller.rawValue:
            profession = .bookseller
        case Profession.herbalist.rawValue:
            profession = .herbalist
        case Profession.barmaid.rawValue:
            profession = .barmaid
        case Profession.entertainer.rawValue:
            profession = .entertainer
        case Profession.tavernKeeper.rawValue, "Innkeeper":
            profession = .tavernKeeper
        case Profession.dockWorker.rawValue:
            profession = .dockWorker
        case Profession.sailor.rawValue:
            profession = .sailor
        case Profession.shipCaptain.rawValue:
            profession = .shipCaptain
        case Profession.pilgrim.rawValue:
            profession = .pilgrim
        case Profession.courtesan.rawValue:
            profession = .courtesan
        case Profession.noProfession.rawValue:
            profession = .noProfession
        case Profession.cleaner.rawValue:
            profession = .cleaner
        default:
            DebugLogService.shared.log("Unknown profession '\(professionString)', defaulting to noProfession", category: "Warning")
            profession = .noProfession
        }
        
        var npc = NPC(name: name, sex: sex, age: age, profession: profession, isVampire: isVampire, id: id)
        npc.homeLocationId = homeLocationId
        
        return npc
    }
} 
