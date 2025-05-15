import Foundation

enum LocationError: Error {
    case locationNotFound
    case invalidData
    case locationsNotLoaded
}

class LocationReader : GameService {
    private static var locations: [[String: Any]] = []
    private static var locationsPool: [Scene] = []
    
    static func loadLocations() {
        if locations.count == 0 {
            //DebugLogService.shared.log("Loading locations from JSON files...", category: "Location")
            var allLocations: [[String: Any]] = []
            var seenIDs = Set<Int>()
            
            // List of kingdom files to load
            let towns = [
                "Duskvale"
            ]
            
            for town in towns {
                //DebugLogService.shared.log("Attempting to load \(town).json", category: "Location")
                if let url = Bundle.main.url(forResource: town, withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let kingdomLocations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    // Check for duplicate IDs in this kingdom file
                    for location in kingdomLocations {
                        if let id = location["id"] as? Int {
                            if seenIDs.contains(id) {
                                DebugLogService.shared.log("⚠️ WARNING: Duplicate ID found in \(town).json: \(id)", category: "Warning")
                                DebugLogService.shared.log("Location name: \(location["name"] as? String ?? "Unknown")", category: "Location")
                                // Skip this location to prevent overwriting
                                continue
                            }
                            seenIDs.insert(id)
                            allLocations.append(location)
                        }
                    }
                    
                    //DebugLogService.shared.log("Successfully loaded \(kingdomLocations.count) locations from \(town)", category: "Location")
                } else {
                    DebugLogService.shared.log("Could not find or load \(town).json", category: "Error")
                }
            }
            
            if allLocations.isEmpty {
                DebugLogService.shared.log("Warning: No locations were loaded from any path!", category: "Warning")
            } else {
                locations = allLocations
            }
        } else {
            //DebugLogService.shared.log("Locations already loaded, count: \(locations.count ?? 0)", category: "Location")
        }
    }
    
    static func getLocations() -> [Scene] {
        loadLocations()
        
        if locationsPool.count > 0 {
            return locationsPool
        }
        do {
            let convertedLocations = locations.compactMap { try? createScene(from: $0) }
            
            locationsPool = convertedLocations
            return locationsPool
        }
    }
    
    static func getCurrentHierarchyLocations(_ parentSceneId: Int) -> [Scene] {
        loadLocations()
        
        return locationsPool.filter { $0.parentSceneId == parentSceneId }
    }
    
    static func getLocation(by id: Int) throws -> Scene {
        loadLocations()
        
        //DebugLogService.shared.log("Searching for location with ID: \(id)", category: "Location")
        for location in locations {
            if let locationId = location["id"] as? Int,
               locationId == id {
                //DebugLogService.shared.log("Found matching location: \(location["name"] as? String ?? "Unknown")", category: "Location")
                return try createScene(from: location)
            }
        }
        
        DebugLogService.shared.log("Location not found with ID: \(id)", category: "Error")
        throw LocationError.locationNotFound
    }
    
    static func getRuntimeLocation(by id: Int) throws -> Scene {
        return getLocations().first(where: { $0.id == id })!
    }
    
    static func getLocationById(by id: Int) -> Scene? {
        if locationsPool.contains(where: { $0.id == id }) {
            return locationsPool.first(where: { $0.id == id })
        } else {
            return nil
        }
    }
    
    static func getSiblingLocations(for locationId: Int) -> [Scene] {
        loadLocations()
        // Ensure the pool is populated (might happen in loadLocations or elsewhere)
        guard !locationsPool.isEmpty else {
            DebugLogService.shared.log("Error: locationsPool is empty in getSiblingLocations.", category: "LocationError")
            // Optionally call loadLocations() here if appropriate, or ensure it's called earlier.
            // loadLocations() // Or ensure loadLocations creates/populates locationsPool
            return []
        }

        // Find the current location *from the pool* to get its parentId
        guard let currentLocation = locationsPool.first(where: { $0.id == locationId }) else {
            DebugLogService.shared.log("Error: Current location ID \(locationId) not found in locationsPool.", category: "LocationError")
            return []
        }
        let parentId = currentLocation.parentSceneId

        // If parentId is 0 or invalid, there are no siblings
        guard parentId != 0 else { return [] }

        // Find all locations *in the pool* with the same parent ID (excluding the current location)
        let siblings = locationsPool.filter { scene in
            return scene.parentSceneId == parentId && scene.id != locationId
        }

        // DebugLogService.shared.log("Found \(siblings.count) sibling locations for ID \(locationId) in locationsPool", category: "Location")
        return siblings
    }
    
    // Modify getParentLocation to use the pool
    static func getParentLocation(for locationId: Int) -> Scene? {
        loadLocations()
        guard let currentLocation = locationsPool.first(where: { $0.id == locationId }),
            currentLocation.parentSceneId != 0 else {
            return nil
        }
        return locationsPool.first { $0.id == currentLocation.parentSceneId }
    }

    // Modify getChildLocations to use the pool
    static func getChildLocations(for locationId: Int) -> [Scene] {
        loadLocations()
       guard let currentLocation = locationsPool.first(where: { $0.id == locationId }) else {
           return []
       }
       // Assuming childSceneIds holds the IDs
       return currentLocation.childSceneIds.compactMap { childId in
           locationsPool.first { $0.id == childId }
       }
    }

    // Add getHubLocations if needed, using the pool
    static func getHubLocations(for locationId: Int) -> [Scene] {
        guard let currentLocation = locationsPool.first(where: { $0.id == locationId }) else {
            return []
        }
        // Assuming hubSceneIds holds the IDs
        return currentLocation.hubSceneIds.compactMap { hubId in
            locationsPool.first { $0.id == hubId }
        }
    }
    
    static func getLocations(by ids: [Int]) throws -> [Scene] {
        loadLocations()
        
        var foundScenes: [Scene] = []
        var notFoundIds: [Int] = []
        
        for id in ids {
            if let location = locations.first(where: { 
                if let locationId = $0["id"] as? Int {
                    return locationId == id
                }
                return false
            }) {
                foundScenes.append(try createScene(from: location))
            } else {
                notFoundIds.append(id)
            }
        }
        
        if !notFoundIds.isEmpty {
            DebugLogService.shared.log("Some locations not found with IDs: \(notFoundIds)", category: "Warning")
        }
        
        return foundScenes
    }
    
    static func getHubScenes(for sceneId: Int) -> [Scene] {
        loadLocations()
        
        //DebugLogService.shared.log("Searching for hub scenes for scene ID: \(sceneId)", category: "Location")
        
        // First get the specified scene
        guard let scene = try? getLocation(by: sceneId) else {
            DebugLogService.shared.log("Scene not found with ID: \(sceneId)", category: "Error")
            return []
        }
        
        // Get hub scenes from the scene's hubSceneIds
        do {
            return try getLocations(by: scene.hubSceneIds)
        } catch {
            DebugLogService.shared.log("Error getting hub scenes: \(error)", category: "Error")
            return []
        }
    }
    
    private static func createScene(from data: [String: Any]) throws -> Scene {
        guard let id = data["id"] as? Int,
              let name = data["name"] as? String,
              let isIndoor = data["isIndoor"] as? Bool,
              let sceneTypeString = data["sceneType"] as? String else {
            DebugLogService.shared.log("Failed to create scene from data: \(data)", category: "Error")
            throw LocationError.invalidData
        }
        
        let x = data["x"] as? Int ?? 0
        let y = data["y"] as? Int ?? 0

        var connectionsArray: [SceneConnection] = []
        if let connectionsData = data["connections"] as? [[String: Any]] {
            for connData in connectionsData {
                if let connectedId = connData["connectedSceneId"] as? Int {
                    let travelTime = connData["travelTime"] as? Double ?? 1.0
                    connectionsArray.append(SceneConnection(connectedSceneId: connectedId, travelTime: travelTime))
                }
            }
        }

        var parentSceneIdValue: Int
        if let parentId = data["parentSceneId"] as? Int {
            parentSceneIdValue = parentId
        } else {
            parentSceneIdValue = 0
        }
        
        let isParent = data["isParent"] as? Bool ?? false
        
        let sceneType: SceneType
        switch sceneTypeString.lowercased() {
        case "alchemistshop": sceneType = .alchemistShop
        case "bathhouse": sceneType = .bathhouse
        case "blacksmith": sceneType = .blacksmith
        case "bookstore": sceneType = .bookstore
        case "brothel": sceneType = .brothel
        case "cathedral": sceneType = .cathedral
        case "cemetery": sceneType = .cemetery
        case "cloister": sceneType = .cloister
        case "district": sceneType = .district
        case "docks": sceneType = .docks
        case "dungeon": sceneType = .dungeon
        case "house": sceneType = .house
        case "manor": sceneType = .manor
        case "military": sceneType = .military
        case "road": sceneType = .road
        case "shop": sceneType = .shop
        case "square": sceneType = .square
        case "tavern": sceneType = .tavern
        case "temple": sceneType = .temple
        case "town": sceneType = .town
        case "warehouse": sceneType = .warehouse
        case "castle": sceneType = .castle
        case "crypt": sceneType = .crypt
        case "mine": sceneType = .mine
        case "forest": sceneType = .forest
        case "cave": sceneType = .cave
        case "ruins": sceneType = .ruins
        default:
            DebugLogService.shared.log("Unknown scene type: \(sceneTypeString), defaulting to .house", category: "Warning")
            sceneType = .house // Default to .house if unknown
        }
        
        let description = data["description"] as? String ?? ""
        
        let scene = Scene(id: id, name: name, 
                          isParent: isParent, parentSceneId: parentSceneIdValue, 
                          parentSceneName: "", 
                          parentSceneType: .house,
                          isIndoor: isIndoor, sceneType: sceneType, 
                          x: x, y: y, connections: connectionsArray)

        if let childIds = data["childSceneIds"] as? [Int] {
            scene.childSceneIds = childIds
        }
        if let hubIds = data["hubSceneIds"] as? [Int] {
            scene.hubSceneIds = hubIds
        }
        
        return scene
    }
    
    static func initializeGameServices() {
        // ... existing code ...
    }
} 
