class LocationGraph {
    var locations: [Int: Scene] = [:] // ID -> Location
    private var adjacencyList: [Int: Set<Int>] = [:] // ID -> Connected IDs
    
    private static var _shared: LocationGraph?
        static var shared: LocationGraph {
            if _shared == nil {
                let locationData = LocationReader.getLocations()
                _shared = LocationGraph(locations: locationData)
            }
            return _shared!
        }
    
    init(locations: [Scene]) {
        // Build lookup dictionary
        locations.forEach { self.locations[$0.id] = $0 }
        
        // Build adjacency list
        for location in locations {
            var connections = Set<Int>()
            
            // 1. Connections to parent
            if location.parentSceneId > 0 {
                connections.insert(location.parentSceneId)
            }
            
            // 2. Connections to children
            let children = locations.filter { $0.parentSceneId == location.id }
            children.forEach { connections.insert($0.id) }
            
            // 3. Hub connections
            if location.hubSceneIds.count > 0 {
                location.hubSceneIds.forEach { connections.insert($0) }
            }
            
            adjacencyList[location.id] = connections
        }
    }
}

extension LocationGraph {
    func shortestPath(from startId: Int, to endId: Int) -> [Int]? {
        var queue = [(startId, [startId])]
        var visited = Set<Int>()
        
        while !queue.isEmpty {
            let (currentId, path) = queue.removeFirst()
            
            if currentId == endId {
                return path
            }
            
            guard let neighbors = adjacencyList[currentId] else { continue }
            
            for neighbor in neighbors where !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append((neighbor, path + [neighbor]))
            }
        }
        
        return nil
    }
    
    func nearestLocation(
            from startId: Int,
            matching predicate: (Scene) -> Bool
        ) -> (path: [Int], target: Scene)? {
            var queue = [(startId, [startId])]
            var visited = Set<Int>()
            
            while !queue.isEmpty {
                let (currentId, path) = queue.removeFirst()
                
                if let location = locations[currentId], predicate(location) {
                    return (path, location)
                }
                
                guard let neighbors = adjacencyList[currentId] else { continue }
                
                for neighbor in neighbors where !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append((neighbor, path + [neighbor]))
                }
            }
            
            return nil
        }
        
        // Convenience methods
        func nearestTavern(from startId: Int) -> [Int]? {
            nearestLocation(from: startId) { $0.sceneType.rawValue == "tavern" }?.path
        }
        
        func nearestIndoor(from startId: Int) -> [Int]? {
            nearestLocation(from: startId) { $0.isIndoor }?.path
        }
        
        func nearestType(_ type: String, from startId: Int) -> [Int]? {
            nearestLocation(from: startId) { $0.sceneType.rawValue == type }?.path
        }
}

extension LocationGraph {
    struct PathfindingOptions {
        var prioritizeIndoor: Bool?
        var preferredTypes: [String] = []
        var maxSteps: Int = 150
    }
    
    func nearestLocation(
        for activity: NPCActivityType,
        from startId: Int,
        time: DayPhase? = nil
    ) -> (path: [Int], location: Scene)? {
        let options = PathfindingOptions(
            prioritizeIndoor: activity.prefersIndoor,
            preferredTypes: time != nil ?
                activity.locationPriority(for: time!) :
                activity.validLocationTypes
        )
        
        return nearestLocation(from: startId, options: options)
    }
    
    private func nearestLocation(
        from startId: Int,
        options: PathfindingOptions
    ) -> (path: [Int], location: Scene)? {
        var queue = [(startId, [startId])]
        var visited = Set<Int>()
        var checkedLocations = 0
        
        while !queue.isEmpty && checkedLocations < options.maxSteps {
            let (currentId, path) = queue.removeFirst()
            
            if let location = locations[currentId],
               matchesCriteria(location: location, options: options) {
                return (path, location)
            }
            
            guard let neighbors = adjacencyList[currentId] else { continue }
            
            // Prioritize neighbors that match preferred types
            let sortedNeighbors = neighbors.sorted { a, b in
                guard let locA = locations[a], let locB = locations[b] else { return false }
                return priorityScore(location: locA, options: options) >
                       priorityScore(location: locB, options: options)
            }
            
            for neighbor in sortedNeighbors where !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append((neighbor, path + [neighbor]))
                checkedLocations += 1
            }
        }
        
        return nil
    }
    
    private func matchesCriteria(location: Scene, options: PathfindingOptions) -> Bool {
        // Check type match
        let typeMatch = options.preferredTypes.isEmpty ||
        options.preferredTypes.contains(location.sceneType.rawValue)
        
        // Check indoor preference
        let indoorMatch = options.prioritizeIndoor == nil ||
                         location.isIndoor == options.prioritizeIndoor
        
        return typeMatch && indoorMatch
    }
    
    private func priorityScore(location: Scene, options: PathfindingOptions) -> Int {
        var score = 0
        
        // Type priority
        if let index = options.preferredTypes.firstIndex(of: location.sceneType.rawValue) {
            score += (options.preferredTypes.count - index) * 10
        }
        
        // Indoor match
        if let preferIndoor = options.prioritizeIndoor,
           preferIndoor == location.isIndoor {
            score += 5
        }
        
        return score
    }
}
