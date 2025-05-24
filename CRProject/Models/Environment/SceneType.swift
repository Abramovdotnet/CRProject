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
        case .cathedral:
            return [.crypt, .stained_glass, .altar]
        case .cloister:
            return [.scriptorium, .bell_tower, .garden]
        case .cemetery:
            return [.grave, .mausoleum, .ossuary]
        case .crypt:
            return [.sarcophagus, .secret_passage]
            
            // Administrative
        case .manor:
            return [.secret_room, .wine_cellar, .attic]
        case .military:
            return [.armory, .barracks, .watchtower]
        case .castle:
            return [.dungeon, .moat, .tower]
            
            // Commercial
        case .blacksmith:
            return [.forge, .coal_storage]
        case .alchemistShop:
            return [.laboratory, .potion_shelf]
        case .warehouse:
            return [.crates, .hidden_compartment]
        case .bookstore:
            return [.archive, .hidden_chamber]
        case .mine:
            return [.tunnel, .miners_nook]
            
            // Entertainment
        case .tavern:
            return [.basement, .keg_storage, .back_room]
        case .brothel:
            return [.boudoir, .secret_passage]
        case .bathhouse:
            return [.steam_room, .underground_pool]
            
            // Public Spaces
        case .square:
            return [.fountain, .statue]
        case .docks:
            return [.ship_hold, .fishing_net_storage]
        case .road:
            return [.none]
            
            // Natural/Wilderness
        case .forest:
            return [.hollow_tree, .thicket, .cave_entrance]
        case .cave:
            return [.dark_recess, .underground_stream]
        case .ruins:
            return [.crumbled_wall, .subterranean_chamber]
            
            // Residential
        case .house:
            return [.root_cellar, .hidden_closet]
        case .dungeon:
            return [.oubliette, .iron_maiden]
        case .shop:
            return [.storage_room, .false_wall]
        case .temple:
            return [.sacred_grove, .inner_sanctum]
            
            // General/Districts
        case .town, .district:
            return [.none]
            
        @unknown default:
            return []
        }
    }
}


