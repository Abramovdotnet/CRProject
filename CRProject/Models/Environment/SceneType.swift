enum SceneType: String, CaseIterable {
    // Huge locations
    case castle
    case royalPalace
    case greatCathedral
    case wizardTower
    case mountainFortress
    case harborCity
    case ancientRuins
    case enchantedForest
    case battlefield
    case palace
    case fortress
    case desert
    case oasis
    case lake

    // Capitals
    case town
    case city
    case kingdom
    
    // Medium locations
    case tavern
    case villageSquare
    case blacksmith
    case alchemistShop
    case library
    case forest
    case temple
    case dungeon
    case crossroads
    case cemetery
    case market
    case farm
    case bridge
    case secretGrove
    case inn
    case hospital
    case outskirts
    case valley
    case mill
    case guardPost
    case herbalistHut
    case arena
    case port
    case lighthouse
    case district
    case shipyard
    case fishery
    case club
    case mine
    case guild
    case tower
    case house
    case residential
    case estate
    case workshop
    case forge
    case academy
    case shrine
    case monastery
    case archive
    case museum
    case gallery
    case concert_hall
    case garrison
    case mages_guild
    case thieves_guild
    case fighters_guild
    
    var isHuge: Bool {
        switch self {
        case .castle, .royalPalace, .greatCathedral, .wizardTower,
                .mountainFortress, .harborCity, .ancientRuins, .forest,
             .enchantedForest, .battlefield, .palace, .fortress, .desert,
             .oasis, .lake:
            return true
        default:
            return false
        }
    }

    var isCapital: Bool {
        switch self {
        case .town, .city, .kingdom:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        let string = self.rawValue
            .map { $0.isUppercase ? " \($0)" : String($0) }
            .joined()
            .capitalized
        
        return string
            .replacingOccurrences(of: " Of ", with: " of ")
            .replacingOccurrences(of: " The ", with: " the ")
    }
    
    var iconName: String {
        switch self {
        case .tavern, .inn: return "mug"
        case .castle, .royalPalace, .palace: return "crown"
        case .blacksmith, .forge: return "hammer"
        case .alchemistShop: return "flask"
        case .temple, .greatCathedral, .shrine, .monastery: return "pray"
        case .dungeon: return "skull"
        case .forest, .enchantedForest: return "tree"
        case .mountainFortress, .fortress: return "mountain"
        case .crossroads: return "signpost"
        case .harborCity, .port: return "ship"
        case .cemetery: return "grave"
        case .market: return "coins"
        case .farm: return "wheat"
        case .bridge: return "bridge"
        case .secretGrove: return "leaf"
        case .wizardTower, .tower: return "hat-wizard"
        case .hospital: return "plus"
        case .outskirts: return "road"
        case .valley: return "hill"
        case .mill: return "windmill"
        case .guardPost, .garrison: return "shield"
        case .library, .archive: return "library"
        case .herbalistHut: return "leaf"
        case .battlefield: return "swords"
        case .ancientRuins: return "ruins"
        case .villageSquare: return "people"
        case .town: return "town"
        case .city: return "city"
        case .kingdom: return "kingdom"
        case .arena: return "swords"
        case .lighthouse: return "lighthouse"
        case .district: return "building"
        case .shipyard: return "ship"
        case .fishery: return "fish"
        case .club: return "music"
        case .mine: return "pickaxe"
        case .guild: return "shield"
        case .desert: return "sun"
        case .oasis: return "water"
        case .lake: return "water"
        case .house: return "house"
        case .residential: return "building"
        case .estate: return "house"
        case .workshop: return "tools"
        case .academy: return "graduation-cap"
        case .museum: return "museum"
        case .gallery: return "image"
        case .concert_hall: return "music"
        case .mages_guild: return "hat-wizard"
        case .thieves_guild: return "mask"
        case .fighters_guild: return "swords"
        default: return "questionmark"
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
        switch type {
        case .battlefield, .dungeon: return Int.random(in: 8...10)
        case .enchantedForest, .ancientRuins: return Int.random(in: 5...7)
        case .outskirts, .cemetery: return Int.random(in: 3...5)
        default: return Int.random(in: 1...3)
        }
    }
    
    private static func calculateNpcCapacity(for type: SceneType) -> Int {
        if type.isHuge {
            return Int.random(in: 15...30)
        } else {
            return Int.random(in: 5...15)
        }
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
