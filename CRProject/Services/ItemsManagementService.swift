//
//  ItemsManagementService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

class ItemsManagementService : GameService {
    static let shared = ItemsManagementService()
    
    func moveItem(item: Item ,from: NPC, to: NPC) {
        if from.items.contains(where: { $0.index == item.index}) {
            from.items.removeAll { $0.index == item.index }
            to.items.append(item)
        }
    }
    
    func moveItem(itemIndex: Int, from: NPC, to: NPC) {
        if from.items.contains(where: { $0.index == itemIndex}) {
            from.items.removeAll { $0.index == itemIndex }
            to.items.append(ItemReader.shared.getItemByIndex(by: itemIndex)!)
        }
    }
    
    func moveItem(item: Item, from: Player, to: NPC) {
        if from.items.contains(where: { $0.index == item.index}) {
            from.items.removeAll { $0.index == item.index }
            to.items.append(item)
        }
    }
    
    func moveItem(itemIndex: Int, from: Player, to: NPC) {
        if from.items.contains(where: { $0.index == itemIndex}) {
            from.items.removeAll { $0.index == itemIndex }
            to.items.append(ItemReader.shared.getItemByIndex(by: itemIndex)!)
        }
    }
    
    func moveItem(item: Item, from: NPC, to: Player) {
        if from.items.contains(where: { $0.index == item.index}) {
            from.items.removeAll { $0.index == item.index }
            to.items.append(item)
        }
    }
    
    func moveItem(itemIndex: Int, from: NPC, to: Player) {
        if from.items.contains(where: { $0.index == itemIndex}) {
            from.items.removeAll { $0.index == itemIndex }
            to.items.append(ItemReader.shared.getItemByIndex(by: itemIndex)!)
        }
    }
    
    func giveItem(item: Item, to: NPC) {
        to.items.append(item)
    }
    
    func giveItem(itemId: Int, to: NPC) {
        to.items.append(ItemReader.shared.getItem(by: itemId)!)
    }
    
    func giveItem(item: Item, to: Player) {
        to.items.append(item)
    }
    
    func giveItem(itemId: Int, to: Player) {
        to.items.append(ItemReader.shared.getItem(by: itemId)!)
    }
    
    func distributeDailyItems() {
        let activeNPCs = NPCReader.getNPCs().filter( { $0.isAlive && !$0.isSpecialBehaviorSet && $0.currentActivity != .sleep })
        let allItems = ItemReader.shared.getItems()
        
        for npc in activeNPCs {
            // Clear existing items
            npc.items.removeAll()
            
            // Basic food and drink items (1-3 items)
            let basicFoodCount = Int.random(in: 1...3)
            let foodItems = allItems.filter { $0.type == .food }
            let drinkItems = allItems.filter { $0.type == .drink }
            
            // Add random food items
            for _ in 0..<basicFoodCount {
                if let randomFood = foodItems.randomElement() {
                    npc.items.append(randomFood)
                }
            }
            
            // Add 1-2 drink items
            let drinkCount = Int.random(in: 1...2)
            for _ in 0..<drinkCount {
                if let randomDrink = drinkItems.randomElement() {
                    npc.items.append(randomDrink)
                }
            }
            
            // Add profession-specific items
            switch npc.profession {
            case .blacksmith:
                // Add tools and weapons
                let tools = allItems.filter { $0.type == .tools && $0.name.contains("Blacksmith") }
                let weapons = allItems.filter { $0.type == .weapon }
                
                // Add 2-3 tools
                let toolCount = Int.random(in: 2...3)
                for _ in 0..<toolCount {
                    if let randomTool = tools.randomElement() {
                        npc.items.append(randomTool)
                    }
                }
                
                // Add 1-2 weapons
                let weaponCount = Int.random(in: 7...20)
                for _ in 0..<weaponCount {
                    if let randomWeapon = weapons.randomElement() {
                        npc.items.append(randomWeapon)
                    }
                }
                
            case .guardman, .cityGuard, .mercenary, .militaryOfficer:
                // Add weapons and armor
                let weapons = allItems.filter { $0.type == .weapon }
                let armor = allItems.filter { $0.type == .armor }
                
                // Add 1-2 weapons
                let weaponCount = Int.random(in: 1...2)
                for _ in 0..<weaponCount {
                    if let randomWeapon = weapons.randomElement() {
                        npc.items.append(randomWeapon)
                    }
                }
                
                // Add 1-2 armor pieces
                let armorCount = Int.random(in: 1...2)
                for _ in 0..<armorCount {
                    if let randomArmor = armor.randomElement() {
                        npc.items.append(randomArmor)
                    }
                }
            
            case .tavernKeeper, .barmaid:
                // Add food and drink
                let foods = allItems.filter { $0.type == .food }
                let drinks = allItems.filter { $0.type == .drink }
                
                let foodCount = Int.random(in: 4...7)
                for _ in 0..<foodCount {
                    if let randomFood = foods.randomElement() {
                        npc.items.append(randomFood)
                    }
                }
                
                let drinkCount = Int.random(in: 6...11)
                for _ in 0..<drinkCount {
                    if let randomDrink = drinks.randomElement() {
                        npc.items.append(randomDrink)
                    }
                }
                
            case .alchemist:
                // Add alchemy items and tools
                let alchemyItems = allItems.filter { $0.type == .alchemy }
                let tools = allItems.filter { $0.type == .tools && $0.name.contains("Potter") }
                
                // Add 2-3 alchemy items
                let alchemyCount = Int.random(in: 5...18)
                for _ in 0..<alchemyCount {
                    if let randomAlchemy = alchemyItems.randomElement() {
                        npc.items.append(randomAlchemy)
                    }
                }
                
                // Add 1-2 tools
                let toolCount = Int.random(in: 1...2)
                for _ in 0..<toolCount {
                    if let randomTool = tools.randomElement() {
                        npc.items.append(randomTool)
                    }
                }
                
            case .merchant:
                // Add various items for trading
                let randomItems = allItems.filter { $0.type != .food && $0.type != .drink }
                let itemCount = Int.random(in: 4...27)
                for _ in 0..<itemCount {
                    if let randomItem = randomItems.randomElement() {
                        npc.items.append(randomItem)
                    }
                }
                
            case .lordLady, .courtesan:
                // Add luxury items with higher probability
                let jewelry = allItems.filter { $0.type == .jewelery }
                let clothing = allItems.filter { $0.type == .clothing }
                
                // Add 1-2 jewelry items (50% chance)
                if Bool.random() {
                    let jewelryCount = Int.random(in: 1...2)
                    for _ in 0..<jewelryCount {
                        if let randomJewelry = jewelry.randomElement() {
                            npc.items.append(randomJewelry)
                        }
                    }
                }
                
                // Add 1-2 luxury clothing items
                let clothingCount = Int.random(in: 1...2)
                for _ in 0..<clothingCount {
                    if let randomClothing = clothing.randomElement() {
                        npc.items.append(randomClothing)
                    }
                }
                
            default:
                // For other professions, add 1-2 random items
                let randomItems = allItems.filter { $0.type != .artefact }
                let itemCount = Int.random(in: 1...2)
                for _ in 0..<itemCount {
                    if let randomItem = randomItems.randomElement() {
                        npc.items.append(randomItem)
                    }
                }
            }
            
            // Ensure NPC doesn't have too many items (max 8)
            if npc.items.count > 8 {
                npc.items = Array(npc.items.prefix(8))
            }
        }
    }
}
