//
//  SmithingSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 25.04.2025.
//

class SmithingSystem {
    static let shared = SmithingSystem()
    
    func getCraftableRecipes(player: Player) -> [Recipe] {
        return RecipeReader.shared.getRecipes().filter { checkCouldCraft(recipe: $0, player: player) }
    }
    
    func getAvailableRecipes(player: Player) -> [Recipe] {
        return RecipeReader.shared.getRecipes().filter { $0.professionLevel <= player.smithingProgress.level }
    }
    
    func checkCouldCraft(recipe: Recipe, player: Player) -> Bool {
        let levelMatch = player.smithingProgress.level >= recipe.professionLevel
        
        // Check if player has all required resources in sufficient quantities
        let resourcesMatch = recipe.requiredResources.allSatisfy { requirement in
            let playerResourceCount = player.items.filter { $0.id == requirement.resourceId }.count
            return playerResourceCount >= requirement.count
        }
        
        let hasHammer = player.items.contains(where: { $0.id == 181 })
        
        return levelMatch && resourcesMatch && hasHammer
    }
    
    func attemptCraft(recipeId: Int, player: Player) -> (Item?, String) {
        let recipe = RecipeReader.shared.getRecipe(by: recipeId)!
        var result: Item?
        var message: String
        
        // Calculate success chance based on player's smithing level
        let baseChance = 0.5 // 50% base chance
        let levelBonus = Double(player.smithingProgress.level) * 0.1 // 10% per level
        let successChance = min(baseChance + levelBonus, 0.95) // Cap at 95% chance
        
        //let success = Double.random(in: 0...1) < successChance
        let success = true 
        
        if success {
            if let craftedItem = craft(recipeId: recipeId, player: player) {
                result = craftedItem
                message = "Successfully crafted \(craftedItem.name)!"
                ItemsManagementService.shared.giveItem(item: craftedItem, to: player)
            } else {
                message = "Failure"
            }
        } else {
            // Resources are still consumed on failure
            for resource in recipe.requiredResources {
                for _ in 0..<resource.count {
                    ItemsManagementService.shared.removeItem(itemId: resource.resourceId, from: player)
                }
            }
            message = "Failure"
        }
        
        return (result, message)
    }
    
    private func craft(recipeId: Int, player: Player) -> Item? {
        let recipe = RecipeReader.shared.getRecipe(by: recipeId)!
        var result: Item?
        
        if checkCouldCraft(recipe: recipe, player: player) {
            for resource in recipe.requiredResources {
                for _ in 0..<resource.count {
                    ItemsManagementService.shared.removeFirstItemById(id: resource.resourceId, from: player)
                }
            }
            
            result = Item.createUnique(ItemReader.shared.getItem(by: recipe.resultItemId)!)
        }
        
        return result
    }
}
