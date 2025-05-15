enum SceneType: String, CaseIterable, Codable {
    // General
    case town
    case castle
    
    // Districts
    case district
    
    // Religious Buildings
    case cathedral
    case cloister
    case cemetery
    case temple
    case crypt
    
    // Administrative Buildings
    case manor
    case military
    
    // Commercial Buildings
    case blacksmith
    case alchemistShop
    case warehouse
    case bookstore
    case shop
    case mine
    
    // Entertainment Buildings
    case tavern
    case brothel
    case bathhouse
    
    // Public Spaces
    case square
    case docks
    case road

    // Natural/Wilderness
    case forest
    case cave
    case ruins
    
    // Misc
    case house
    case dungeon

    
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
        case .cemetery: return "cross.fill"
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
        case .docks: return "water.waves"
        case .house: return "house.fill"
        case .dungeon: return "lock.fill"
        case .shop: return "tag.fill"
        case .temple: return "staroflife.fill"
        case .castle: return "shield.lefthalf.filled.slash"
        case .crypt: return "archivebox.fill"
        case .mine: return "pickaxe.fill"
        case .forest: return "tree.fill"
        case .cave: return "circle.bottomhalf.filled"
        case .ruins: return "building.columns.fill"
        }
    }
    
    func possibleHidingCells() -> [HidingCell] {
            switch self {
            // Religious Buildings
            case .cathedral, .cloister:
                return [.shadow]
                
            case .cemetery:
                return [.shadow]
                
            case .crypt:
                return [.shadow]
                
            // Administrative
            case .manor:
                return [.shadow]
                
            case .military:
                return [.shadow]
                
            case .castle:
                return [.shadow]
                
            // Commercial
            case .blacksmith:
                return [.shadow]
                
            case .alchemistShop:
                return [.shadow]
                
            case .warehouse:
                return [.shadow]
                
            case .bookstore:
                return [.shadow]
                
            case .mine:
                return [.shadow]
                
            // Entertainment
            case .tavern:
                return [.shadow]
                
            case .brothel:
                return [.shadow]
                
            case .bathhouse:
                return [.shadow]
                
            // Public Spaces
            case .square:
                return [.shadow]
                
            case .docks:
                return [.shadow]
                
            case .road:
                return [.none]
                
            // Natural/Wilderness
            case .forest:
                return [.shadow, .none]
                
            case .cave:
                return [.shadow]
                
            case .ruins:
                return [.shadow]
                
            // Residential
            case .house:
                return [.shadow]
                
            case .dungeon:
                return [.shadow]
                
            // General/Districts
            case .town, .district:
                return [.none]
                
            // Новые типы    
            case .shop:
                return []
            case .temple:
                return []
                
            @unknown default:
                return []
            }
        }
}

enum HidingCell: String, Codable, CaseIterable {
    case shadow = "hide"
    case none = "none"
    
    var iconName: String {
        switch self {
        case .shadow:
            return "square.stack.3d.down.right.fill"
        case .none:
            return "xmark.circle.fill"
        }
    }
    
    var description: String {
        return rawValue.capitalized
    }
}
