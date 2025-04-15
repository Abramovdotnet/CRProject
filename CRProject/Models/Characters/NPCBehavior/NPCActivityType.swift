import Foundation
import SwiftUICore

enum NPCActivityType: String, CaseIterable, Codable {
    // Core Activities
    case sleep = "Sleeping"
    case eat = "Eating"
    case idle = "Idling"
    case travel = "Traveling"
    
    // Work-Related
    case craft = "Crafting"
    case sell = "Selling"
    case repair = "Repairing"
    case guardPost = "Guarding"
    case patrol = "Patrolling"
    case research = "Researching"
    case train = "Training"
    case manage = "Managing"
    case clean = "Cleaning"
    case serve = "Serving"
    case entertain = "Entertaining"
    case harvest = "Harvesting"
    case cook = "Cooking"
    case transport = "Transporting"
    
    // Social/Leisure
    case socialize = "Socializing"
    case pray = "Praying"
    case study = "Studying"
    case drink = "Drinking"
    case gamble = "Gambling"
    case bathe = "Bathing"
    case explore = "Exploring"
    
    // Special
    case quest = "Questing"
    case smuggle = "Smuggling"
    case spy = "Spying"
    case love = "Love"
    case flirt = "Flirting"
    
    // Action activities
    case seductedByPlayer = "Seducted"
    case duzzled = "Duzzled"
    case fleeing = "Fleeing"
    case casualty = "Casualty"
    case followingPlayer = "Following"
    case allyingPlayer = "Allying"
    
    var description: String {
        return self.rawValue
    }
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
        case .patrol: return ["district", "quarter", "square" , "road"]
        case .research: return ["bookstore", "cathedral", "monastery"]
        case .train: return ["military", "barracks"]
        case .manage: return ["manor", "keep", "market"]
        case .clean: return ["house", "manor", "barracks", "keep"]
        case .serve: return ["tavern", "manor", "keep"]
        case .entertain: return ["tavern", "brothel", "square", "road"]
        case .harvest: return ["alchemistShop", "square"] // Gardens/plants
        case .cook: return ["house", "manor", "tavern"]
        case .transport: return ["warehouse", "docks", "market"]
        
        // Social/Leisure
        case .socialize: return ["tavern", "square", "market", "bathhouse"]
        case .pray: return ["cathedral", "monastery", "crypt"]
        case .study: return ["bookstore", "cathedral"]
        case .drink: return ["tavern", "brothel", "house", "road"]
        case .gamble: return ["tavern", "brothel"]
        case .bathe: return ["bathhouse"]
        case .explore: return ["crypt", "district"] // Exploration sites
        
        // Special
        case .quest: return ["tavern", "keep"] // Quest givers
        case .smuggle: return ["docks", "warehouse"]
        case .spy: return ["brothel", "tavern", "road"]
        case .love: return []
        case .flirt: return []
            
        // Action
        case .seductedByPlayer: return []
        case .duzzled: return []
        case .fleeing: return ["military", "watchtower", "barracks", "manor", "tavern", "cathedral", "monastery"]
        case .casualty: return ["military", "watchtower", "barracks"]
        case .followingPlayer: return []
        case .allyingPlayer: return []
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

extension NPCActivityType {
    var icon: String {
        switch self {
        // Core Activities
        case .sleep: return "moon.zzz.fill"
        case .eat: return "fork.knife"
        case .idle: return "person.fill"
        case .travel: return "figure.walk"
        
        // Work-Related
        case .craft: return "hammer.fill"
        case .sell: return "bag.fill"
        case .repair: return "wrench.fill"
        case .guardPost: return "shield.checkered"
        case .patrol: return "figure.walk"
        case .research: return "book.fill"
        case .train: return "dumbbell.fill"
        case .manage: return "person.fill.badge.plus"
        case .clean: return "broom.fill"
        case .serve: return "tray.fill"
        case .entertain: return "music.note"
        case .harvest: return "leaf.fill"
        case .cook: return "flame.fill"
        case .transport: return "shippingbox.fill"
        
        // Social/Leisure
        case .socialize: return "person.2.fill"
        case .pray: return "cross.fill"
        case .study: return "book.closed.fill"
        case .drink: return "mug.fill"
        case .gamble: return "dice.fill"
        case .bathe: return "shower.fill"
        case .explore: return "map.fill"
        
        // Special
        case .quest: return "star.fill"
        case .smuggle: return "briefcase.fill"
        case .spy: return "eye.fill"
        case .love: return "heart.fill"
        case .flirt: return "heart"
            
        // Action
        case .seductedByPlayer: return "heart.fill"
        case .duzzled: return "hand.thumbsup.fill"
        case .fleeing: return "figure.run"
        case .casualty: return "xmark.circle.fill"
        case .followingPlayer: return "person.2.fill"
        case .allyingPlayer: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        // Core Activities
        case .sleep: return .blue
        case .eat: return .orange
        case .idle: return .gray
        case .travel: return .brown
        
        // Work-Related
        case .craft: return .orange
        case .sell: return .blue
        case .repair: return .brown
        case .guardPost: return .red
        case .patrol: return .red
        case .research: return .purple
        case .train: return .red
        case .manage: return .blue
        case .clean: return .gray
        case .serve: return .blue
        case .entertain: return .purple
        case .harvest: return .green
        case .cook: return .orange
        case .transport: return .brown
        
        // Social/Leisure
        case .socialize: return .purple
        case .pray: return .purple
        case .study: return .blue
        case .drink: return .orange
        case .gamble: return .red
        case .bathe: return .blue
        case .explore: return .green
        
        // Special
        case .quest: return .yellow
        case .smuggle: return .red
        case .spy: return .purple
        case .love: return .pink
        case .flirt: return .red
            
        // Action
        case .seductedByPlayer: return .red
        case .duzzled: return .pink
        case .fleeing: return .red
        case .casualty: return .red
        case .followingPlayer: return .blue
        case .allyingPlayer : return .green
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
        // Crafting Professions
        case .blacksmith: return [.craft, .repair, .sell, .research]
        case .carpenter: return [.craft, .repair]
        case .tailor: return [.craft, .sell]
        case .alchemist: return [.craft, .research, .sell, .research]
        case .herbalist: return [.harvest, .research, .sell, .research]
        
        // Military/Security
        case .guardman: return [.guardPost, .patrol]
        case .cityGuard: return [.guardPost, .patrol, .train]
        case .militaryOfficer: return [.manage, .train, .patrol]
        
        // Religious
        case .priest: return [.pray, .study, .manage, .research]
        case .monk: return [.pray, .study, .clean]
        case .religiousScholar: return [.study, .research]
        case .pilgrim: return [.pray, .study]
        
        // Trade/Merchants
        case .merchant: return [.sell, .manage, .transport]
        case .bookseller: return [.sell, .study]
        
        // Food/Entertainment
        case .tavernKeeper: return [.manage, .serve]
        case .barmaid: return [.serve, .entertain]
        case .entertainer: return [.entertain]
        case .courtesan: return [.entertain]
        case .kitchenStaff: return [.cook, .clean]
        
        // Labor/Transport
        case .dockWorker: return [.transport, .repair]
        case .sailor: return [.transport, .repair]
        case .shipCaptain: return [.manage, .transport]
        case .stableHand: return [.clean, .transport]
        case .gardener: return [.harvest, .clean]
        case .maintenanceWorker: return [.repair, .clean]
        case .cleaner: return [.clean]
        case .generalLaborer: return [.transport, .clean, .repair]
        
        // Administration/Nobility
        case .administrator: return [.manage, .study]
        case .lordLady: return [.manage, .entertain]
        
        // Service
        case .servant: return [.serve, .clean]
        
        // Specialized
        case .adventurer: return [.explore, .quest]
        case .mercenary: return [.quest, .explore]
        case .thug: return [.quest, .explore]
        
        // Learning/Unemployed
        case .apprentice: return [.study, .craft]
        case .noProfession: return [.explore]
        }
    }
    
    /// Additional leisure activities available
    private var leisureActivities: [NPCActivityType] {
        switch self {
        // Nobility/High Status
        case .lordLady: return [.drink, .gamble, .bathe, .entertain]
        case .courtesan: return [.drink, .bathe, .entertain]
        
        // Entertainment Industry
        case .entertainer: return [.drink, .socialize, .bathe]
        case .tavernKeeper: return [.drink, .gamble]
        case .barmaid: return [.drink]
        
        // Military/Security
        case .guardman, .cityGuard, .militaryOfficer:
            return [.drink, .gamble]
        
        // Maritime Professions
        case .sailor, .dockWorker, .shipCaptain:
            return [.drink, .gamble]
        
        // Religious
        case .priest, .monk, .religiousScholar, .pilgrim:
            return [.pray, .study]
        
        // Craftsmen/Tradespeople
        case .blacksmith, .carpenter, .tailor, .alchemist, .herbalist:
            return [.drink, .study]
        case .merchant, .bookseller:
            return [.drink, .gamble]
        
        // Laborers
        case .gardener, .stableHand, .maintenanceWorker, .generalLaborer:
            return [.drink]
        case .cleaner:
            return [.drink, .bathe]
        
        // Domestic/Service
        case .servant, .kitchenStaff:
            return [.socialize, .bathe]
        
        // Adventurous
        case .adventurer:
            return [.drink, .gamble, .explore]
        
        // Special Cases
        case .apprentice: return [.study]
        case .noProfession: return [.idle, .socialize, .gamble, .drink, .entertain]
            
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
