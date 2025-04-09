enum SceneType: String, CaseIterable {
    // Districts
    case district
    
    // Religious Buildings
    case cathedral
    case cloister
    case cemetery
    
    // Administrative Buildings
    case manor
    case military
    
    // Commercial Buildings
    case blacksmith
    case alchemistShop
    case warehouse
    case bookstore
    
    // Entertainment Buildings
    case tavern
    case brothel
    case bathhouse
    
    // Public Spaces
    case square
    
    var isHuge: Bool {
        return false
    }

    var isCapital: Bool {
        return false
    }
    
    var displayName: String {
        let string = self.rawValue
            .replacingOccurrences(of: "_", with: " ")
            .map { $0.isUppercase ? " \($0)" : String($0) }
            .joined()
            .capitalized
        
        return string
            .replacingOccurrences(of: " Of ", with: " of ")
            .replacingOccurrences(of: " The ", with: " the ")
    }
    
    var iconName: String {
        switch self {
        case .bathhouse: return "building.2.fill"
        case .manor: return "house.lodge.fill"
        case .military: return "shield.fill"
        case .cathedral: return "building.columns.fill"
        case .cloister: return "building.columns.fill"
        case .cemetery: return "moon.stars.fill"
        case .blacksmith: return "hammer.fill"
        case .alchemistShop: return "flask.fill"
        case .warehouse: return "building.columns.fill"
        case .bookstore: return "books.vertical.fill"
        case .tavern: return "cup.and.saucer.fill"
        case .brothel: return "building.2.fill"
        case .district: return "building.fill"
        case .square: return "square.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

class SceneInfo {
    var isHuge: Bool
    var isCapital: Bool
    var type: SceneType
    var npcCapacity: Int
    
    init(type: SceneType) {
        self.type = type
        self.isHuge = type.isHuge
        self.isCapital = type.isCapital
        self.npcCapacity = SceneInfo.calculateNpcCapacity(for: type)
    }
    
    private static func calculateDangerLevel(for type: SceneType) -> Int {
        return Int.random(in: 1...3)
    }
    
    private static func calculateNpcCapacity(for type: SceneType) -> Int {
        return Int.random(in: 5...15)
    }
    
    var description: String {
        return """
        \(type.displayName)
        Is Capital: \(isCapital ? "Yes" : "No")
        Size: \(isHuge ? "Huge" : "Medium")
        NPCs: \(npcCapacity)
        """
    }
}
