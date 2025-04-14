enum SceneType: String, CaseIterable {
    // General
    case town
    
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
    case docks
    case road

    // Misc
    case house

    
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
        case .brothel: return "heart.fill"
        case .district: return "building.fill"
        case .square: return "square.fill"
        case .town: return "house.fill"
        case .road: return "road.lane.arrowtriangle.2.inward"
        case .docks: return "building.columns.fill"
        case .house: return "house.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    func possibleHidingCells() -> [HidingCell] {
            switch self {
            // Religious Buildings
            case .cathedral, .cloister:
                return [.basement, .attic, .grave]
                
            case .cemetery:
                return [.grave, .basement]
                
            // Administrative
            case .manor:
                return [.basement, .attic, .roof]
                
            case .military:
                return [.basement, .roof]
                
            // Commercial
            case .blacksmith:
                return [.basement]
                
            case .alchemistShop:
                return [.basement, .attic]
                
            case .warehouse:
                return [.basement, .roof]
                
            case .bookstore:
                return [.basement]
                
            // Entertainment
            case .tavern:
                return [.basement, .attic]
                
            case .brothel:
                return [.basement, .attic]
                
            case .bathhouse:
                return [.basement]
                
            // Public Spaces
            case .square:
                return [.none]
                
            case .docks:
                return [.sewer, .basement]
                
            case .road:
                return [.none]
                
            // Residential
            case .house:
                return [.basement, .attic, .roof]
                
            // General/Districts
            case .town, .district:
                return [.none]
                
            @unknown default:
                return []
            }
        }
}

enum HidingCell: String, Codable, CaseIterable {
    case basement = "basement"
    case attic = "attic"
    case grave = "grave"
    case roof = "roof"
    case sewer = "sewer"
    case none = "none"
    
    var iconName: String {
        switch self {
        case .basement:
            return "square.stack.3d.down.right.fill"
        case .attic:
            return "clock.fill"
        case .grave:
            return "cross.fill"
        case .roof:
            return "house.fill"
        case .sewer:
            return "aqi.medium"
        case .none:
            return "xmark.circle.fill"
        }
    }
    
    var description: String {
        return rawValue.capitalized
    }
}
