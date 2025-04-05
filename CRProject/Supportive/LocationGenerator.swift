import Foundation

class LocationGenerator {
    private static let hugeLocationNames = [
        "Northern Realm", "Eastern Empire", "Southern Kingdom", "Western Dominion",
        "Central Province", "Coastal Region", "Mountain Domain"
    ]
    
    private static let townPrefixes = ["Old", "New", "Great", "Little", "Upper", "Lower", "East", "West", "North", "South"]
    private static let townSuffixes = ["town", "burg", "ville", "ford", "bridge", "haven", "port", "shire", "field", "wood"]
    
    private static let districtTypes = [
        "Market", "Residential", "Noble", "Industrial", "Harbor", "Temple", "Garden",
        "Artisan", "Merchant", "Scholar", "Military", "Entertainment", "Slums", "Commerce"
    ]
    
    private static let estateTypes = [
        "Tavern", "Inn", "Castle", "Manor", "Bank", "Store", "Church", "Temple",
        "Blacksmith", "Library", "Market", "Guild Hall", "Theater", "Warehouse"
    ]
    
    static func generateLocations() -> [[String: Any]] {
        DebugLogService.shared.log("Starting location generation...", category: "Location")
        var locations: [[String: Any]] = []
        
        // Generate huge locations
        for hugeName in hugeLocationNames {
            DebugLogService.shared.log("Generating huge location: \(hugeName)", category: "Location")
            let hugeId = UUID()
            locations.append([
                "id": hugeId.uuidString,
                "name": hugeName,
                "parentSceneId": "",
                "isIndoor": false
            ])
            
            // Generate towns for each huge location
            let townCount = Int.random(in: 3...10)
            for _ in 0..<townCount {
                let townId = UUID()
                let townName = "\(townPrefixes.randomElement()!) \(townSuffixes.randomElement()!)"
                DebugLogService.shared.log("  Generating town: \(townName)", category: "Location")
                locations.append([
                    "id": townId.uuidString,
                    "name": townName,
                    "parentSceneId": hugeId.uuidString,
                    "isIndoor": false
                ])
                
                // Generate districts for each town
                let districtCount = Int.random(in: 10...30)
                for _ in 0..<districtCount {
                    let districtId = UUID()
                    let districtName = "\(districtTypes.randomElement()!) District"
                    locations.append([
                        "id": districtId.uuidString,
                        "name": districtName,
                        "parentSceneId": townId.uuidString,
                        "isIndoor": false
                    ])
                    
                    // Generate estates for each district
                    let estateCount = Int.random(in: 4...5)
                    for _ in 0..<estateCount {
                        let estateType = estateTypes.randomElement()!
                        let estateName = "\(townName) \(estateType)"
                        locations.append([
                            "id": UUID().uuidString,
                            "name": estateName,
                            "parentSceneId": districtId.uuidString,
                            "isIndoor": true
                        ])
                    }
                }
            }
        }
        
        DebugLogService.shared.log("Generated \(locations.count) total locations", category: "Location")
        return locations
    }
    
    static func saveToFile() {
        DebugLogService.shared.log("Starting save to file...", category: "Location")
        let locations = generateLocations()
        DebugLogService.shared.log("Converting to JSON...", category: "Location")
        let jsonData = try! JSONSerialization.data(withJSONObject: locations, options: .prettyPrinted)
        
        DebugLogService.shared.log("Creating Data directory if needed...", category: "Location")
        // Create Data directory if it doesn't exist
        let fileManager = FileManager.default
        let dataDirectory = "Data"
        if !fileManager.fileExists(atPath: dataDirectory) {
            try! fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
        }
        
        DebugLogService.shared.log("Writing to file...", category: "Location")
        let fileURL = URL(fileURLWithPath: "Data/Locations.json")
        try! jsonData.write(to: fileURL)
        DebugLogService.shared.log("Generated \(locations.count) locations and saved to Locations.json", category: "Location")
    }
}

// Call saveToFile when the script is run
//LocationGenerator.saveToFile() 
