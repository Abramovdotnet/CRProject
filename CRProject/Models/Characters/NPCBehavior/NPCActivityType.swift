import Foundation

enum NPCActivityType: String, CaseIterable, Codable {
    // Core Activities
    case sleep
    case eat
    case idle
    case travel
    
    // Work-Related
    case craft
    case sell
    case repair
    case guardPost
    case patrol
    case research
    case train
    case manage
    case clean
    case serve
    case entertain
    case harvest
    case cook
    case transport
    
    // Social/Leisure
    case socialize
    case pray
    case study
    case drink
    case gamble
    case bathe
    case explore
    
    // Special
    case quest
    case smuggle
    case spy
}

extension NPCActivityType {
    var validLocationTypes: [String] {
        switch self {
        // Core Activities
        case .sleep: return ["house", "manor", "cottage", "barracks", "keep"]
        case .eat: return ["tavern", "house", "manor", "keep", "barracks"]
        case .idle: return [] // Can idle anywhere
        case .travel: return [] // Anywhere during travel
        
        // Work-Related
        case .craft: return ["blacksmith", "alchemistShop", "bookstore"]
        case .sell: return ["market", "shop", "tavern", "square"]
        case .repair: return ["blacksmith", "warehouse"]
        case .guardPost: return ["military", "watchtower", "barracks"]
        case .patrol: return ["district", "quarter", "square"]
        case .research: return ["bookstore", "cathedral", "monastery"]
        case .train: return ["military", "barracks"]
        case .manage: return ["manor", "keep", "market"]
        case .clean: return ["house", "manor", "barracks", "keep"]
        case .serve: return ["tavern", "manor", "keep"]
        case .entertain: return ["tavern", "brothel", "square"]
        case .harvest: return ["alchemistShop", "square"] // Gardens/plants
        case .cook: return ["house", "manor", "tavern"]
        case .transport: return ["warehouse", "docks", "market"]
        
        // Social/Leisure
        case .socialize: return ["tavern", "square", "market", "bathhouse"]
        case .pray: return ["cathedral", "monastery", "crypt"]
        case .study: return ["bookstore", "cathedral"]
        case .drink: return ["tavern", "brothel", "house"]
        case .gamble: return ["tavern", "brothel"]
        case .bathe: return ["bathhouse"]
        case .explore: return ["crypt", "district"] // Exploration sites
        
        // Special
        case .quest: return ["tavern", "keep"] // Quest givers
        case .smuggle: return ["docks", "warehouse"]
        case .spy: return ["brothel", "tavern"]
        }
    }
    
    var prefersIndoor: Bool? {
        switch self {
        case .sleep, .craft, .research: return true
        case .patrol, .explore: return false
        default: return nil
        }
    }
    
    func locationPriority(for time: DayPhase) -> [String] {
        switch self {
        case .drink:
            return time == .night ? ["tavern", "brothel"] : ["house", "manor"]
        case .pray:
            return time == .earlyMorning ? ["cathedral"] : ["monastery"]
        case .socialize:
            return time == .evening ? ["tavern"] : ["square", "market"]
        case .sleep:
            return time == .lateNight ? ["house", "cottage"] : ["barracks"] // Guards sleep in barracks
        case .bathe:
            return time == .morning ? ["manor"] : ["bathhouse"]
        default:
            return validLocationTypes
        }
    }
}


extension Profession {
    /// Base activities available to all professions
    private var baseActivities: [NPCActivityType] {
        return [.sleep, .eat, .idle, .socialize]
    }
    
    /// Profession-specific work activities
    private var workActivities: [NPCActivityType] {
        switch self {
        case .blacksmith: return [.craft, .repair, .sell]
        case .priest: return [.pray, .study, .manage]
        case .guardman: return [.guardPost, .patrol, .train]
        case .merchant: return [.sell, .manage, .transport]
        case .barmaid: return [.serve, .entertain]
        case .adventurer: return [.explore, .quest, .gamble]
        case .lordLady: return [.manage, .entertain, .gamble]
        // ... other professions
        default: return []
        }
    }
    
    /// Additional leisure activities available
    private var leisureActivities: [NPCActivityType] {
        switch self {
        case .lordLady, .courtesan, .entertainer:
            return [.drink, .gamble, .bathe, .entertain]
        case .guardman, .sailor, .dockWorker:
            return [.drink, .gamble]
        case .priest, .monk:
            return [.pray, .study]
        default:
            return [.drink]
        }
    }
    
    /// Returns all activities this profession can perform
    func typicalActivities() -> [NPCActivityType] {
        return baseActivities + workActivities + leisureActivities
    }
    
    /// Activities prioritized during work hours
    func primaryWorkActivities() -> [NPCActivityType] {
        return workActivities.isEmpty ? [.idle] : workActivities
    }
    
    /// Activities available during leisure time
    func primaryLeisureActivities() -> [NPCActivityType] {
        let allLeisure = baseActivities + leisureActivities
        return allLeisure.filter { $0 != .idle } // Prefer more interesting activities
    }
}
