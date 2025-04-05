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
            var seenIDs = Set<String>()
            
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
                    
                    // Check for duplicate IDs in this kingdom file
                    for location in kingdomLocations {
                        if let id = location["id"] as? String {
                            if seenIDs.contains(id) {
                                print("⚠️ WARNING: Duplicate ID found in \(kingdomFile).json: \(id)")
                                print("Location name: \(location["name"] as? String ?? "Unknown")")
                                // Skip this location to prevent overwriting
                                continue
                            }
                            seenIDs.insert(id)
                            allLocations.append(location)
                        }
                    }
                    
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
        
        // First find the current location
        guard let location = locations?.first(where: { 
            if let idString = $0["id"] as? String,
               let id = UUID(uuidString: idString) {
                return id == locationId
            }
            return false
        }),
        let parentIdString = location["parentSceneId"] as? String,
        !parentIdString.isEmpty,
        let parentId = UUID(uuidString: parentIdString),
        let parentData = locations?.first(where: {
            if let idString = $0["id"] as? String,
               let id = UUID(uuidString: idString) {
                return id == parentId
            }
            return false
        }) else {
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
        
        // Validate and normalize UUID string
        func normalizeUUID(_ uuidString: String) -> String? {
            // Remove any non-hex characters and ensure proper length
            let hexOnly = uuidString.filter { "0123456789abcdefABCDEF".contains($0) }
            guard hexOnly.count == 32 else {
                print("Invalid UUID length: \(hexOnly.count) for string: \(uuidString)")
                return nil
            }
            
            // Format as proper UUID string (8-4-4-4-12)
            let parts = [
                String(hexOnly.prefix(8)),
                String(hexOnly.dropFirst(8).prefix(4)),
                String(hexOnly.dropFirst(12).prefix(4)),
                String(hexOnly.dropFirst(16).prefix(4)),
                String(hexOnly.dropFirst(20))
            ]
            return parts.joined(separator: "-")
        }
        
        // Parse scene ID
        guard let normalizedId = normalizeUUID(idString),
              let id = UUID(uuidString: normalizedId) else {
            print("Failed to create valid UUID from string: \(idString)")
            throw LocationError.invalidData
        }
        
        // Handle parent scene ID
        let parentSceneId: UUID?
        if let parentSceneIdString = data["parentSceneId"] as? String,
           !parentSceneIdString.isEmpty,
           parentSceneIdString.lowercased() != "null",
           let normalizedParentId = normalizeUUID(parentSceneIdString),
           let parentId = UUID(uuidString: normalizedParentId) {
            parentSceneId = parentId
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
        case "guardPost": sceneType = .guard_post
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
        case "mages_guild": sceneType = .mages_guild
        case "thieves_guild": sceneType = .thieves_guild
        case "fighters_guild": sceneType = .fighters_guild
        case "mine": sceneType = .mine
        case "mountain_pass": sceneType = .mountain_pass
        case "museum": sceneType = .museum
        case "observatory": sceneType = .observatory
        case "port": sceneType = .port
        case "road": sceneType = .road
        case "ruins": sceneType = .ruins
        case "shipyard": sceneType = .shipyard
        case "tower": sceneType = .tower
        case "village": sceneType = .village
        case "wilderness": sceneType = .wilderness
        case "garden": sceneType = .garden
        case "gallery": sceneType = .gallery
        case "concert_hall": sceneType = .concert_hall
        case "garrison": sceneType = .garrison
        case "city_gate": sceneType = .city_gate
        case "docks": sceneType = .docks
        case "cave": sceneType = .cave
        case "guard_post": sceneType = .guard_post
        case "district": sceneType = .district
        case "archive": sceneType = .archive
        case "forge": sceneType = .forge
        case "fishery": sceneType = .fishery
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
