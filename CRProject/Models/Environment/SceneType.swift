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

enum HidingCell: String, Codable, CaseIterable {
    case none = "none"
    
    // Religious
    case crypt = "crypt"
    case stained_glass = "stained_glass"
    case altar = "altar"
    case scriptorium = "scriptorium"
    case bell_tower = "bell_tower"
    case grave = "grave"
    case mausoleum = "mausoleum"
    case ossuary = "ossuary"
    case sarcophagus = "sarcophagus"
    
    // Residential
    case secret_room = "secret_room"
    case wine_cellar = "wine_cellar"
    case attic = "attic"
    case root_cellar = "root_cellar"
    case hidden_closet = "hidden_closet"
    case dungeon = "dungeon"
    
    // Military
    case armory = "armory"
    case barracks = "barracks"
    case watchtower = "watchtower"
    case tower = "tower"
    case moat = "moat"
    case oubliette = "oubliette"
    case iron_maiden = "iron_maiden"
    
    // Commercial
    case crates = "crates"
    case forge = "forge"
    case coal_storage = "coal_storage"
    case laboratory = "laboratory"
    case potion_shelf = "potion_shelf"
    case hidden_compartment = "hidden_compartment"
    case archive = "archive"
    case hidden_chamber = "hidden_chamber"
    case tunnel = "tunnel"
    case miners_nook = "miners_nook"
    case storage_room = "storage_room"
    
    // Entertainment
    case basement = "basement"
    case keg_storage = "keg_storage"
    case back_room = "back_room"
    case boudoir = "boudoir"
    case steam_room = "steam_room"
    case underground_pool = "underground_pool"
    
    // Public
    case fountain = "fountain"
    case statue = "statue"
    case ship_hold = "ship_hold"
    case fishing_net_storage = "fishing_net_storage"
    
    // Natural
    case hollow_tree = "hollow_tree"
    case thicket = "thicket"
    case cave_entrance = "cave_entrance"
    case dark_recess = "dark_recess"
    case underground_stream = "underground_stream"
    case crumbled_wall = "crumbled_wall"
    case subterranean_chamber = "subterranean_chamber"
    
    // Special
    case secret_passage = "secret_passage"
    case false_wall = "false_wall"
    case garden = "garden"
    case sacred_grove = "sacred_grove"
    case inner_sanctum = "inner_sanctum"
    
    var iconName: String {
        switch self {
        case .crypt: return "building.columns.fill"
        case .stained_glass: return "square.fill.on.square.fill"
        case .altar: return "flame.fill"
        case .scriptorium: return "book.closed.fill"
        case .bell_tower: return "bell.fill"
        case .grave: return "cross.fill"
        case .mausoleum: return "building.fill"
        case .ossuary: return "bone.fill"
        case .sarcophagus: return "rectangle.compress.vertical.fill"
            
        case .secret_room: return "door.left.hand.closed"
        case .wine_cellar: return "wineglass.fill"
        case .attic: return "clock.fill"
        case .root_cellar: return "leaf.fill"
        case .hidden_closet: return "hanger"
        case .dungeon: return "door.locked"
            
        case .armory: return "shield.lefthalf.fill"
        case .barracks: return "bed.double.fill"
        case .watchtower: return "binoculars.fill"
        case .tower: return "arrow.up.left.circle.fill"
        case .moat: return "drop.fill"
        case .oubliette: return "lock.fill"
        case .iron_maiden: return "person.fill.xmark"
            
        case .crates: return "shippingbox.fill"
        case .forge: return "hammer.fill"
        case .coal_storage: return "cube.fill"
        case .laboratory: return "testtube.2"
        case .potion_shelf: return "pills.fill"
        case .hidden_compartment: return "circle.grid.2x2.fill"
        case .archive: return "archivebox.fill"
        case .hidden_chamber: return "door.right.hand.open"
        case .tunnel: return "road.lanes.curved.left"
        case .miners_nook: return "signpost.right.fill"
        case .storage_room: return "square.split.bottomrightquarter.fill"
            
        case .basement: return "square.split.2x1.fill"
        case .keg_storage: return "chart.bar.fill"
        case .back_room: return "sofa.fill"
        case .boudoir: return "bed.double"
        case .steam_room: return "cloud.fog.fill"
        case .underground_pool: return "water.waves"
            
        case .fountain: return "water.waves"
        case .statue: return "person.arms.spread"
        case .ship_hold: return "sailboat.fill"
        case .fishing_net_storage: return "net"
            
        case .hollow_tree: return "tree.fill"
        case .thicket: return "tree.fill"
        case .cave_entrance: return "mountain.2.fill"
        case .dark_recess: return "moon.stars.fill"
        case .underground_stream: return "water.waves"
        case .crumbled_wall: return "rectangle.portrait.slash"
        case .subterranean_chamber: return "rectangle.portrait.bottomthird.inset.filled"
            
        case .secret_passage: return "arrow.left.arrow.right"
        case .false_wall: return "square.dashed"
        case .garden: return "laurel.leading"
        case .sacred_grove: return "tree.circle.fill"
        case .inner_sanctum: return "lock.circle.fill"
            
        case .none: return "xmark.circle.fill"
        }
    }
    
    var description: String {
        return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
