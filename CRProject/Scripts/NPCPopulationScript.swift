/*import Foundation

// Models
struct Location: Codable {
    var id: Int
    var name: String
    var sceneType: String
    var isParent: Bool
    var parentSceneId: Int?
    var isIndoor: Bool
}

struct NPC: Codable {
    var id: Int
    var name: String
    var sex: String
    var age: Int
    var profession: String
    var homeLocationId: Int
    var isVampire: Bool
}

// Location categories with capacity limits (±15% randomness)
let locationCategories: [String: (types: [String], min: Int, max: Int)] = [
    "military": (["military", "barracks", "watchtower"], 18, 22),
    "tavern": (["tavern"], 7, 9),
    "religious": (["cathedral", "cloister"], 9, 11),
    "noble": (["manor", "keep"], 7, 9),
    "square": (["square"], 2, 4),
    "house": (["house"], 3, 5),
    "blacksmith": (["blacksmith", "forge"], 3, 5),
    "alchemistShop": (["alchemistShop", "herbalist"], 3, 5),
    "bookstore": (["bookstore"], 3, 5),
    "docks": (["docks", "pier"], 5, 7),
    "warehouse": (["warehouse"], 9, 11),
    "brothel": (["brothel"], 7, 9),
    "market": (["market"], 3, 5),
    "shop": (["shop"], 3, 5),
    "inn": (["inn"], 5, 7),
    "bathhouse": (["bathhouse"], 3, 5),
    "road": (["road"], 1, 3)
]

// Special locations that need specific NPCs
let specialLocations: [String: [(profession: String, min: Int, max: Int)]] = [
    "Guard Barracks": [
        ("Military officer", 3, 4),
        ("City guard", 8, 10)
    ],
    "NW Watchtower": [
        ("Military officer", 2, 3),
        ("City guard", 6, 8)
    ],
    "SE Watchtower": [
        ("Military officer", 2, 3),
        ("City guard", 6, 8)
    ],
    "The Velvet Veil": [
        ("Courtesan", 2, 3),
        ("Cleaner", 1, 2)
    ],
    "The Herbalist's Den": [
        ("Herbalist", 1, 2),
        ("Apprentice", 1, 2)
    ],
    "The Steel Anvil": [
        ("Blacksmith", 1, 2),
        ("Apprentice", 1, 2)
    ],
    "Shining Steel": [
        ("Blacksmith", 1, 2),
        ("Apprentice", 1, 2)
    ],
    "Docks Guard Barracks": [
        ("Military officer", 3, 4),
        ("City guard", 8, 10)
    ]
]

// Outdoor special locations for beggars
let outdoorSpecialLocations: [String: (min: Int, max: Int)] = [
    "The Crest Square": (2, 3),
    "Fountain of the Ancients": (2, 3),
    "The Verdant Court": (2, 3)
]

// Load NPCs and locations
let npcData = try! Data(contentsOf: URL(fileURLWithPath: "CRProject/Data/NPCs.json"))
let locationData = try Data(contentsOf: URL(fileURLWithPath: "CRProject/Data/Duskvale/Duskvale.json"))

var npcs = try! JSONDecoder().decode([NPC].self, from: npcData)
let locations = try JSONDecoder().decode([Location].self, from: locationData)

print("\nLoaded data:")
print("- NPCs: \(npcs.count)")
print("- Locations: \(locations.count)")

// Filter out excluded location types and create a map of valid locations
let validLocations = Dictionary(uniqueKeysWithValues: locations
    .filter { !["district", "town"].contains($0.sceneType.lowercased()) }
    .map { ($0.id, (name: $0.name, type: $0.sceneType, isIndoor: $0.isIndoor)) })

print("\nValid location types:")
Dictionary(grouping: validLocations.values, by: { $0.type })
    .mapValues { $0.count }
    .sorted { $0.key < $1.key }
    .forEach { print("\($0.key): \($0.value) locations") }

// Function to get random count within range
func randomCount(min: Int, max: Int) -> Int {
    return Int.random(in: min...max)
}

// Function to assign NPCs to special locations
func assignSpecialLocations() {
    print("\nAssigning NPCs to special locations...")
    
    for (locationName, requiredProfessions) in specialLocations {
        if let locationId = validLocations.first(where: { $0.value.name == locationName })?.key {
            for requirement in requiredProfessions {
                let suitableNPCs = npcs.filter { npc in
                    guard npc.homeLocationId == 0 else { return false }
                    return npc.profession.lowercased() == requirement.profession.lowercased()
                }
                
                let count = randomCount(min: requirement.min, max: requirement.max)
                let npcsToAssign = Array(suitableNPCs.shuffled().prefix(count))
                
                for npc in npcsToAssign {
                    if let npcIndex = npcs.firstIndex(where: { $0.id == npc.id }) {
                        npcs[npcIndex].homeLocationId = locationId
                        print("Assigned \(npc.name) (profession: \(requirement.profession)) to \(locationName)")
                    }
                }
            }
        }
    }
}

// Function to assign beggars to outdoor locations
func assignBeggars() {
    print("\nAssigning beggars to outdoor locations...")
    
    // First assign to special outdoor locations
    for (locationName, range) in outdoorSpecialLocations {
        if let locationId = validLocations.first(where: { $0.value.name == locationName })?.key {
            let beggars = npcs.filter { $0.profession == "No profession" && $0.homeLocationId == 0 }
            let count = randomCount(min: range.min, max: range.max)
            let npcsToAssign = Array(beggars.shuffled().prefix(count))
            
            for npc in npcsToAssign {
                if let npcIndex = npcs.firstIndex(where: { $0.id == npc.id }) {
                    npcs[npcIndex].homeLocationId = locationId
                    print("Assigned beggar \(npc.name) to \(locationName)")
                }
            }
        }
    }
    
    // Then assign to roads
    let roads = validLocations.filter { $0.value.type.lowercased() == "road" }
    for (locationId, _) in roads {
        let beggars = npcs.filter { $0.profession == "No profession" && $0.homeLocationId == 0 }
        let count = randomCount(min: 1, max: 3)
        let npcsToAssign = Array(beggars.shuffled().prefix(count))
        
        for npc in npcsToAssign {
            if let npcIndex = npcs.firstIndex(where: { $0.id == npc.id }) {
                npcs[npcIndex].homeLocationId = locationId
                print("Assigned beggar \(npc.name) to road \(locationId)")
            }
        }
    }
}

// Function to assign remaining NPCs to indoor locations
func assignRemainingNPCs() {
    print("\nAssigning remaining NPCs to indoor locations...")
    
    let indoorLocations = validLocations.filter { $0.value.isIndoor }
    var remainingNPCs = npcs.filter { $0.homeLocationId == 0 }
    
    // Special case for The Long Pier
    if let longPierId = validLocations.first(where: { $0.value.name == "The Long Pier" })?.key {
        let count = randomCount(min: 5, max: 7)
        let npcsToAssign = Array(remainingNPCs.prefix(count))
        
        for npc in npcsToAssign {
            if let npcIndex = npcs.firstIndex(where: { $0.id == npc.id }) {
                npcs[npcIndex].homeLocationId = longPierId
                print("Assigned \(npc.name) to The Long Pier")
                remainingNPCs.removeAll { $0.id == npc.id }
            }
        }
    }
    
    for (locationId, locationDetails) in indoorLocations {
        // Skip if location already has NPCs
        if npcs.contains(where: { $0.homeLocationId == locationId }) {
            continue
        }
        
        let locationType = locationDetails.type.lowercased()
        let category = locationCategories.first { $0.value.types.contains { $0.lowercased() == locationType } }
        
        if let category = category {
            let count = randomCount(min: category.value.min, max: category.value.max)
            let npcsToAssign = Array(remainingNPCs.prefix(count))
            
            for npc in npcsToAssign {
                if let npcIndex = npcs.firstIndex(where: { $0.id == npc.id }) {
                    npcs[npcIndex].homeLocationId = locationId
                    print("Assigned \(npc.name) to \(locationDetails.name)")
                    remainingNPCs.removeAll { $0.id == npc.id }
                }
            }
        }
    }
}

// Main assignment function
func assignNPCs() {
    // First, handle military locations
    assignSpecialLocations()
    
    // Then assign beggars to outdoor locations
    assignBeggars()
    
    // Finally assign remaining NPCs to indoor locations
    assignRemainingNPCs()
}

// Run the assignment
assignNPCs()

// Save updated NPCs
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let jsonData = try! encoder.encode(npcs)
try! jsonData.write(to: URL(fileURLWithPath: "CRProject/Data/NPCs.json"))

// Print statistics
print("\nAssignment complete:")
print("- Total NPCs: \(npcs.count)")
print("- Assigned NPCs: \(npcs.filter { $0.homeLocationId != 0 }.count)")
print("- Unassigned NPCs: \(npcs.filter { $0.homeLocationId == 0 }.count)")

// Print location statistics
let populatedLocations = Set(npcs.compactMap { $0.homeLocationId })
let validLocationIds = Set(validLocations.keys)
print("\nLocation Statistics:")
print("Total valid locations: \(validLocations.count)")
print("Populated locations: \(populatedLocations.count)")
print("Empty valid locations: \(validLocationIds.subtracting(populatedLocations).count)")

// Print empty locations
print("\nEmpty locations:")
for locationId in validLocationIds.subtracting(populatedLocations).sorted() {
    if let details = validLocations[locationId] {
        print("\(details.name), Type: \(details.type)")
    }
}
*/
