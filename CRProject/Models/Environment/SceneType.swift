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
    case mountain_pass
    case wilderness
    case ruins
    case observatory

    // Capitals and major settlements
    case town
    case city
    case kingdom
    case village
    
    // Districts and areas
    case district
    case docks
    case city_gate
    
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
    case guard_post
    case herbalistHut
    case arena
    case port
    case lighthouse
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
    case garden
    case cave
    case road
    
    var isHuge: Bool {
        switch self {
        case .castle, .royalPalace, .greatCathedral, .wizardTower,
             .mountainFortress, .harborCity, .ancientRuins, .forest,
             .enchantedForest, .battlefield, .palace, .fortress, .desert,
             .oasis, .lake, .mountain_pass, .wilderness, .ruins,
             .observatory:
            return true
        default:
            return false
        }
    }

    var isCapital: Bool {
        switch self {
        case .town, .city, .kingdom, .village:
            return true
        default:
            return false
        }
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
        case .tavern, .inn: return "cup.and.saucer.fill"
        case .castle, .royalPalace, .palace: return "crown.fill"
        case .blacksmith, .forge: return "hammer.fill"
        case .alchemistShop: return "flask.fill"
        case .temple, .greatCathedral, .shrine, .monastery: return "building.columns.fill"
        case .dungeon, .cave: return "exclamationmark.triangle.fill"
        case .forest, .enchantedForest: return "leaf.fill"
        case .mountainFortress, .fortress, .mountain_pass: return "mountain.2.fill"
        case .crossroads, .road: return "arrow.triangle.branch"
        case .harborCity, .port, .docks: return "ferry.fill"
        case .cemetery: return "moon.stars.fill"
        case .market: return "cart.fill"
        case .farm: return "leaf.arrow.circlepath"
        case .bridge: return "arrow.left.and.right"
        case .secretGrove, .garden: return "sparkles"
        case .wizardTower, .tower, .observatory: return "building.2.fill"
        case .hospital: return "cross.case.fill"
        case .outskirts: return "arrow.forward"
        case .valley: return "hills"
        case .mill: return "rotate.3d"
        case .guard_post, .garrison, .city_gate: return "shield.fill"
        case .library, .archive: return "books.vertical.fill"
        case .herbalistHut: return "leaf.fill"
        case .battlefield: return "shield.lefthalf.filled"
        case .ancientRuins, .ruins: return "building.columns"
        case .villageSquare: return "person.3.fill"
        case .town, .village: return "building.2"
        case .city: return "building.2.crop.circle"
        case .kingdom: return "crown.fill"
        case .arena: return "figure.boxing"
        case .lighthouse: return "light.beacon.max.fill"
        case .district: return "square.grid.2x2.fill"
        case .shipyard: return "ferry.fill"
        case .fishery: return "fish.fill"
        case .club: return "music.note"
        case .mine: return "pickaxe.fill"
        case .guild: return "person.2.fill"
        case .desert: return "sun.max.fill"
        case .oasis: return "drop.fill"
        case .lake: return "water.waves"
        case .house: return "house.fill"
        case .residential: return "building.fill"
        case .estate: return "house.lodge.fill"
        case .workshop: return "wrench.and.screwdriver.fill"
        case .academy: return "graduationcap.fill"
        case .museum: return "building.columns.fill"
        case .gallery: return "photo.fill"
        case .concert_hall: return "music.note.house.fill"
        case .mages_guild: return "wand.and.stars"
        case .thieves_guild: return "person.crop.circle"
        case .fighters_guild: return "shield.fill"
        case .wilderness: return "leaf.fill"
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
