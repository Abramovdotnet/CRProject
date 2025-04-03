import Foundation

enum LocationError: Error {
    case locationNotFound
    case invalidData
    case locationsNotLoaded
}

class LocationReader : GameService {
    private static var locations: [[String: Any]]?
    
    static func loadLocations() {
        if locations == nil {
            print("Loading locations from JSON files...")
            var allLocations: [[String: Any]] = []
            
            // List of kingdom files to load
            let kingdomFiles = [
                "NorthernRealm",
                "WesternTerritories",
                "EasternEmpire",
                "SouthernIsles",
                "CentralPlains"
            ]
            
            for kingdomFile in kingdomFiles {
                print("Attempting to load \(kingdomFile).json")
                if let url = Bundle.main.url(forResource: kingdomFile, withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let kingdomLocations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    allLocations.append(contentsOf: kingdomLocations)
                    print("Successfully loaded \(kingdomLocations.count) locations from \(kingdomFile)")
                } else {
                    print("Could not find or load \(kingdomFile).json")
                }
            }
            
            if allLocations.isEmpty {
                print("Warning: No locations were loaded from any path!")
            } else {
                locations = allLocations
                print("Successfully loaded \(locations?.count ?? 0) total locations")
                
                // Print location details for debugging
                for location in locations ?? [] {
                    if let name = location["name"] as? String,
                       let id = location["id"] as? String,
                       let parentId = location["parentSceneId"] as? String {
                        print("Location: \(name), ID: \(id), Parent ID: \(parentId)")
                    }
                }
            }
        } else {
            print("Locations already loaded, count: \(locations?.count ?? 0)")
        }
    }
    
    static func getLocation(by id: UUID) throws -> Scene {
        loadLocations()
        
        guard let locations = locations else {
            print("Locations array is nil")
            throw LocationError.locationsNotLoaded
        }
        
        print("Searching for location with ID: \(id)")
        for location in locations {
            if let locationIdString = location["id"] as? String,
               let locationId = UUID(uuidString: locationIdString),
               locationId == id {
                print("Found matching location: \(location["name"] as? String ?? "Unknown")")
                return try createScene(from: location)
            }
        }
        
        print("Location not found with ID: \(id)")
        throw LocationError.locationNotFound
    }
    
    static func getChildLocations(for parentId: UUID) -> [Scene] {
        loadLocations()
        
        print("Searching for child locations of parent ID: \(parentId)")
        let childLocations = locations?
            .filter { 
                if let parentSceneIdString = $0["parentSceneId"] as? String,
                   let parentSceneId = UUID(uuidString: parentSceneIdString) {
                    let isMatch = parentSceneId == parentId
                    if isMatch {
                        print("Found child location: \($0["name"] as? String ?? "Unknown") with parent ID: \(parentSceneId)")
                    }
                    return isMatch
                }
                return false
            }
            .compactMap { try? createScene(from: $0) }
            ?? []
        
        print("Found \(childLocations.count) child locations")
        return childLocations
    }
    
    static func getSiblingLocations(for locationId: UUID) -> [Scene] {
        loadLocations()
        
        print("Searching for sibling locations of location ID: \(locationId)")
        
        // First find the current location and its parent ID
        guard let location = locations?.first(where: { 
            if let idString = $0["id"] as? String,
               let id = UUID(uuidString: idString) {
                return id == locationId
            }
            return false
        }),
        let parentIdString = location["parentSceneId"] as? String,
        let parentId = UUID(uuidString: parentIdString),
        !parentIdString.isEmpty else {
            print("Could not find location or parent ID")
            return []
        }
        
        print("Found parent ID: \(parentId)")
        
        // Find all locations with the same parent ID (excluding the current location)
        let siblings = locations?
            .filter { 
                if let idString = $0["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let siblingParentIdString = $0["parentSceneId"] as? String,
                   let siblingParentId = UUID(uuidString: siblingParentIdString) {
                    let isSibling = siblingParentId == parentId && id != locationId
                    if isSibling {
                        print("Found sibling location: \($0["name"] as? String ?? "Unknown")")
                    }
                    return isSibling
                }
                return false
            }
            .compactMap { try? createScene(from: $0) }
            ?? []
        
        print("Found \(siblings.count) sibling locations")
        return siblings
    }
    
    static func getParentLocation(for locationId: UUID) -> Scene? {
        loadLocations()
        
        guard let location = locations?.first(where: { ($0["id"] as? String) == locationId.uuidString }),
              let parentId = location["parentSceneId"] as? String,
              !parentId.isEmpty,
              let parentData = locations?.first(where: { ($0["id"] as? String) == parentId }) else {
            return nil
        }
        
        return try? createScene(from: parentData)
    }
    
    private static func createScene(from data: [String: Any]) throws -> Scene {
        guard let idString = data["id"] as? String,
              let name = data["name"] as? String,
              let isIndoor = data["isIndoor"] as? Bool,
              let sceneTypeString = data["sceneType"] as? String else {
            print("Failed to create scene from data: \(data)")
            throw LocationError.invalidData
        }
        
        // Convert invalid UUID characters to valid hexadecimal
        let validIdString = idString
            .replacingOccurrences(of: "G", with: "a")
            .replacingOccurrences(of: "H", with: "b")
            .replacingOccurrences(of: "I", with: "c")
            .replacingOccurrences(of: "J", with: "d")
            .replacingOccurrences(of: "K", with: "e")
            .replacingOccurrences(of: "L", with: "f")
            .replacingOccurrences(of: "M", with: "0")
            .replacingOccurrences(of: "N", with: "1")
            .replacingOccurrences(of: "O", with: "2")
            .replacingOccurrences(of: "P", with: "3")
            .replacingOccurrences(of: "Q", with: "4")
            .replacingOccurrences(of: "R", with: "5")
            .replacingOccurrences(of: "S", with: "6")
            .replacingOccurrences(of: "T", with: "7")
            .replacingOccurrences(of: "U", with: "8")
            .replacingOccurrences(of: "V", with: "9")
            .replacingOccurrences(of: "W", with: "a")
            .replacingOccurrences(of: "X", with: "b")
            .replacingOccurrences(of: "Y", with: "c")
            .replacingOccurrences(of: "Z", with: "d")
        
        guard let id = UUID(uuidString: validIdString) else {
            print("Failed to create UUID from string: \(validIdString)")
            throw LocationError.invalidData
        }
        
        // Handle null or empty parentSceneId for root locations
        let parentSceneId: UUID?
        if let parentSceneIdString = data["parentSceneId"] as? String,
           !parentSceneIdString.isEmpty,
           parentSceneIdString.lowercased() != "null" {
            let validParentIdString = parentSceneIdString
                .replacingOccurrences(of: "G", with: "a")
                .replacingOccurrences(of: "H", with: "b")
                .replacingOccurrences(of: "I", with: "c")
                .replacingOccurrences(of: "J", with: "d")
                .replacingOccurrences(of: "K", with: "e")
                .replacingOccurrences(of: "L", with: "f")
                .replacingOccurrences(of: "M", with: "0")
                .replacingOccurrences(of: "N", with: "1")
                .replacingOccurrences(of: "O", with: "2")
                .replacingOccurrences(of: "P", with: "3")
                .replacingOccurrences(of: "Q", with: "4")
                .replacingOccurrences(of: "R", with: "5")
                .replacingOccurrences(of: "S", with: "6")
                .replacingOccurrences(of: "T", with: "7")
                .replacingOccurrences(of: "U", with: "8")
                .replacingOccurrences(of: "V", with: "9")
                .replacingOccurrences(of: "W", with: "a")
                .replacingOccurrences(of: "X", with: "b")
                .replacingOccurrences(of: "Y", with: "c")
                .replacingOccurrences(of: "Z", with: "d")
            parentSceneId = UUID(uuidString: validParentIdString)
        } else {
            parentSceneId = nil
        }
        
        // Convert sceneType string to SceneType enum
        let sceneType: SceneType
        switch sceneTypeString {
        case "kingdom": sceneType = .kingdom
        case "city": sceneType = .city
        case "castle": sceneType = .castle
        case "tavern": sceneType = .tavern
        case "inn": sceneType = .inn
        case "blacksmith": sceneType = .blacksmith
        case "market": sceneType = .market
        case "library": sceneType = .library
        case "temple": sceneType = .temple
        case "hospital": sceneType = .hospital
        case "alchemistShop": sceneType = .alchemistShop
        case "herbalistHut": sceneType = .herbalistHut
        case "mill": sceneType = .mill
        case "farm": sceneType = .farm
        case "bridge": sceneType = .bridge
        case "cemetery": sceneType = .cemetery
        case "guardPost": sceneType = .guardPost
        case "wizardTower": sceneType = .wizardTower
        case "mountainFortress": sceneType = .mountainFortress
        case "battlefield": sceneType = .battlefield
        case "ancientRuins": sceneType = .ancientRuins
        case "valley": sceneType = .valley
        case "enchantedForest": sceneType = .enchantedForest
        case "secretGrove": sceneType = .secretGrove
        case "outskirts": sceneType = .outskirts
        case "villageSquare": sceneType = .villageSquare
        case "dungeon": sceneType = .dungeon
        case "harborCity": sceneType = .harborCity
        case "royalPalace": sceneType = .royalPalace
        case "greatCathedral": sceneType = .greatCathedral
        case "crossroads": sceneType = .crossroads
        default: 
            print("Unknown scene type: \(sceneTypeString), defaulting to castle")
            sceneType = .castle
        }
        
        let scene = Scene()
        scene.id = id
        scene.name = name
        scene.isIndoor = isIndoor
        scene.parentSceneId = parentSceneId
        scene.sceneType = sceneType
        return scene
    }
} 
