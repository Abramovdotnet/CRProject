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
            print("Loading locations from JSON...")
            guard let fileURL = Bundle.main.url(forResource: "Locations", withExtension: "json") else {
                print("Failed to find Locations.json in bundle")
                return
            }
            print("Found JSON file at: \(fileURL)")
            do {
                let data = try Data(contentsOf: fileURL)
                print("Successfully read JSON data")
                if let loadedLocations = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    locations = loadedLocations
                    print("Successfully loaded \(loadedLocations.count) locations")
                    // Print all location IDs for debugging
                    for location in loadedLocations {
                        if let id = location["id"] as? String {
                            print("Found location with ID: \(id)")
                        }
                    }
                } else {
                    print("Failed to parse JSON as array of dictionaries")
                }
            } catch {
                print("Error loading locations: \(error)")
                print("File URL: \(fileURL)")
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
            if let locationId = location["id"] as? String,
               UUID(uuidString: locationId) == id {
                print("Found matching location: \(location["name"] as? String ?? "Unknown")")
                return try createScene(from: location)
            }
        }
        
        print("Location not found with ID: \(id)")
        throw LocationError.locationNotFound
    }
    
    static func getChildLocations(for parentId: UUID) -> [Scene] {
        loadLocations()
        
        return locations?
            .filter { ($0["parentSceneId"] as? String) == parentId.uuidString }
            .compactMap { try? createScene(from: $0) }
            ?? []
    }
    
    static func getSiblingLocations(for locationId: UUID) -> [Scene] {
        loadLocations()
        
        guard let location = locations?.first(where: { ($0["id"] as? String) == locationId.uuidString }),
              let parentId = location["parentSceneId"] as? String else {
            return []
        }
        
        return locations?
            .filter { ($0["parentSceneId"] as? String) == parentId && ($0["id"] as? String) != locationId.uuidString }
            .compactMap { try? createScene(from: $0) }
            ?? []
    }
    
    static func getParentLocation(for locationId: UUID) -> Scene? {
        loadLocations()
        
        guard let location = locations?.first(where: { ($0["id"] as? String) == locationId.uuidString }),
              let parentId = location["parentSceneId"] as? String,
              let parentData = locations?.first(where: { ($0["id"] as? String) == parentId }) else {
            return nil
        }
        
        return try? createScene(from: parentData)
    }
    
    private static func createScene(from data: [String: Any]) throws -> Scene {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let parentSceneIdString = data["parentSceneId"] as? String,
              let parentSceneId = UUID(uuidString: parentSceneIdString),
              let isIndoor = data["isIndoor"] as? Bool else {
            print("Failed to create scene from data: \(data)")
            throw LocationError.invalidData
        }
        
        return Scene(
            id: id,
            name: name,
            isIndoor: isIndoor,
            parentSceneId: parentSceneId
        )
    }
} 
