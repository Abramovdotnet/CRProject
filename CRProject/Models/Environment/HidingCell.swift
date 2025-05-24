//
//  HidingCell.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 23.05.2025.
//


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
        switch self {
        case .none: return "None"
        case .crypt: return "Crypt"
        case .stained_glass: return "Stained Glass"
        case .altar: return "Altar"
        case .scriptorium: return "Scriptorium"
        case .bell_tower: return "Bell Tower"
        case .grave: return "Grave"
        case .mausoleum: return "Mausoleum"
        case .ossuary: return "Ossuary"
        case .sarcophagus: return "Sarcophagus"
        case .secret_room: return "Secret Room"
        case .wine_cellar: return "Wine Cellar"
        case .attic: return "Attic"
        case .root_cellar: return "Root Cellar"
        case .hidden_closet: return "Hidden Closet"
        case .dungeon: return "Dungeon"
        case .armory: return "Armory"
        case .barracks: return "Barracks"
        case .watchtower: return "Watchtower"
        case .tower: return "Tower"
        case .moat: return "Moat"
        case .oubliette: return "Oubliette"
        case .iron_maiden: return "Iron Maiden"
        case .crates: return "Crates"
        case .forge: return "Forge"
        case .coal_storage: return "Coal Storage"
        case .laboratory: return "Laboratory"
        case .potion_shelf: return "Potion Shelf"
        case .hidden_compartment: return "Hidden Compartment"
        case .archive: return "Archive"
        case .hidden_chamber: return "Hidden Chamber"
        case .tunnel: return "Tunnel"
        case .miners_nook: return "Miner's Nook"
        case .storage_room: return "Storage Room"
        case .basement: return "Basement"
        case .keg_storage: return "Keg Storage"
        case .back_room: return "Back Room"
        case .boudoir: return "Boudoir"
        case .steam_room: return "Steam Room"
        case .underground_pool: return "Underground Pool"
        case .fountain: return "Fountain"
        case .statue: return "Statue"
        case .ship_hold: return "Ship Hold"
        case .fishing_net_storage: return "Fishing Net Storage"
        case .hollow_tree: return "Hollow Tree"
        case .thicket: return "Thicket"
        case .cave_entrance: return "Cave Entrance"
        case .dark_recess: return "Dark Recess"
        case .underground_stream: return "Underground Stream"
        case .crumbled_wall: return "Crumbled Wall"
        case .subterranean_chamber: return "Subterranean Chamber"
        case .secret_passage: return "Secret Passage"
        case .false_wall: return "False Wall"
        case .garden: return "Garden"
        case .sacred_grove: return "Sacred Grove"
        case .inner_sanctum: return "Inner Sanctum"
        }
    }
}