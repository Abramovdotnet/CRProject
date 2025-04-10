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
            DebugLogService.shared.log("Loading locations from JSON files...", category: "Location")
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
                DebugLogService.shared.log("Attempting to load \(kingdomFile).json", category: "Location")
                if let url = Bundle.main.url(forResource: kingdomFile, withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let kingdomLocations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    // Check for duplicate IDs in this kingdom file
                    for location in kingdomLocations {
                        if let id = location["id"] as? String {
                            if seenIDs.contains(id) {
                                DebugLogService.shared.log("⚠️ WARNING: Duplicate ID found in \(kingdomFile).json: \(id)", category: "Warning")
                                DebugLogService.shared.log("Location name: \(location["name"] as? String ?? "Unknown")", category: "Location")
                                // Skip this location to prevent overwriting
                                continue
                            }
                            seenIDs.insert(id)
                            allLocations.append(location)
                        }
                    }
                    
                    DebugLogService.shared.log("Successfully loaded \(kingdomLocations.count) locations from \(kingdomFile)", category: "Location")
                } else {
                    DebugLogService.shared.log("Could not find or load \(kingdomFile).json", category: "Error")
                }
            }
            
            if allLocations.isEmpty {
                DebugLogService.shared.log("Warning: No locations were loaded from any path!", category: "Warning")
            } else {
                locations = allLocations
                DebugLogService.shared.log("Successfully loaded \(locations?.count ?? 0) total locations", category: "Location")
                
                // Print location details for debugging
                for location in locations ?? [] {
                    if let name = location["name"] as? String,
                       let id = location["id"] as? String,
                       let parentId = location["parentSceneId"] as? String {
                        DebugLogService.shared.log("Location: \(name), ID: \(id), Parent ID: \(parentId)", category: "Location")
                    }
                }
            }
        } else {
            DebugLogService.shared.log("Locations already loaded, count: \(locations?.count ?? 0)", category: "Location")
        }
    }
    
    static func getLocation(by id: Int) throws -> Scene {
        loadLocations()
        
        guard let locations = locations else {
            DebugLogService.shared.log("Locations array is nil", category: "Error")
            throw LocationError.locationsNotLoaded
        }
        
        DebugLogService.shared.log("Searching for location with ID: \(id)", category: "Location")
        for location in locations {
            if let locationId = location["id"] as? Int,
               locationId == id {
                DebugLogService.shared.log("Found matching location: \(location["name"] as? String ?? "Unknown")", category: "Location")
                return try createScene(from: location)
            }
        }
        
        DebugLogService.shared.log("Location not found with ID: \(id)", category: "Error")
        throw LocationError.locationNotFound
    }
    
    static func getChildLocations(for parentId: Int) -> [Scene] {
        loadLocations()
        
        DebugLogService.shared.log("Searching for child locations of parent ID: \(parentId)", category: "Location")
        let childLocations = locations?
            .filter { 
                if let parentSceneId = $0["parentSceneId"] as? Int {
                    let isMatch = parentSceneId == parentId
                    if isMatch {
                        DebugLogService.shared.log("Found child location: \($0["name"] as? String ?? "Unknown") with parent ID: \(parentSceneId)", category: "Location")
                    }
                    return isMatch
                }
                return false
            }
            .compactMap { try? createScene(from: $0) }
            ?? []
        
        DebugLogService.shared.log("Found \(childLocations.count) child locations", category: "Location")
        return childLocations
    }
    
    static func getSiblingLocations(for locationId: Int) -> [Scene] {
        loadLocations()
        
        DebugLogService.shared.log("Searching for sibling locations of location ID: \(locationId)", category: "Location")
        
        // First find the current location and its parent ID
        guard let location = locations?.first(where: { 
            if let id = $0["id"] as? Int {
                return id == locationId
            }
            return false
        }),
        let parentId = location["parentSceneId"] as? Int else { return [] }
        
        DebugLogService.shared.log("Found parent ID: \(parentId)", category: "Location")
        
        // Find all locations with the same parent ID (excluding the current location)
        let siblings = locations?
            .filter { 
                if let id = $0["id"] as? Int,
                   let siblingParentId = $0["parentSceneId"] as? Int {
                    let isSibling = siblingParentId == parentId && id != locationId
                    if isSibling {
                        DebugLogService.shared.log("Found sibling location: \($0["name"] as? String ?? "Unknown")", category: "Location")
                    }
                    return isSibling
                }
                return false
            }
            .compactMap { try? createScene(from: $0) }
            ?? []
        
        DebugLogService.shared.log("Found \(siblings.count) sibling locations", category: "Location")
        return siblings
    }
    
    static func getParentLocation(for locationId: Int) -> Scene? {
        loadLocations()
        
        // First find the current location
        guard let location = locations?.first(where: { 
            if let id = $0["id"] as? Int {
                return id == locationId
            }
            return false
        }),
        let parentId = location["parentSceneId"] as? Int,
        let parentData = locations?.first(where: {
            if let id = $0["id"] as? Int {
                return id == parentId
            }
            return false
        }) else {
            return nil
        }
        
        return try? createScene(from: parentData)
    }
    
    private static func createScene(from data: [String: Any]) throws -> Scene {
        guard let id = data["id"] as? Int,
              let name = data["name"] as? String,
              let isIndoor = data["isIndoor"] as? Bool,
              let sceneTypeString = data["sceneType"] as? String else {
            DebugLogService.shared.log("Failed to create scene from data: \(data)", category: "Error")
            throw LocationError.invalidData
        }
        
        // Handle parent scene ID
        var parentSceneId: Int
        if let parentId = data["parentSceneId"] as? Int {
            parentSceneId = parentId
        } else {
            parentSceneId = 0
        }
        
        // Convert sceneType string to SceneType enum
        let sceneType: SceneType
        switch sceneTypeString {
        case "alchemistShop": sceneType = .alchemistShop
        case "bathhouse": sceneType = .bathhouse
        case "blacksmith": sceneType = .blacksmith
        case "bookstore": sceneType = .bookstore
        case "brotherl": sceneType = .brothel
        case "cathedral": sceneType = .cathedral
        case "cemetery": sceneType = .cemetery
        case "cloister": sceneType = .cloister
        case "district": sceneType = .district
        case "docks": sceneType = .docks
        case "house": sceneType = .house
        case "manor": sceneType = .manor
        case "military": sceneType = .military
        case "square": sceneType = .square
        case "tavern": sceneType = .tavern
        case "warehouse": sceneType = .warehouse
        default: 
            DebugLogService.shared.log("Unknown scene type: \(sceneTypeString), defaulting to castle", category: "Warning")
            sceneType = .house
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
