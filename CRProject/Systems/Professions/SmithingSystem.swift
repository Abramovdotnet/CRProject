//
//  SmithingSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 25.04.2025.
//

class SmithingSystem {
    static let shared = SmithingSystem()
    
    func getCraftableRecipes(player: Player) -> [Recipe] {
        // Early exit if player doesn't have a hammer (O(n) check, but only once)
        guard player.items.contains(where: { $0.id == 181 }) else {
            return []
        }
        
        // Fetch all recipes (assuming RecipeReader.shared.getRecipes() is cached)
        let allRecipes = RecipeReader.shared.getRecipes()
        
        // Use the optimized batch-checking function (O(n + m*k) complexity)
        return checkCouldCraft(recipes: allRecipes, player: player)
    }
    
    func getAvailableRecipes(player: Player) -> [Recipe] {
        return RecipeReader.shared.getRecipes().filter { $0.professionLevel <= player.smithingProgress.level }
    }
    
    func checkCouldCraft(recipe: Recipe, player: Player) -> Bool {
        guard player.smithingProgress.level >= recipe.professionLevel else { return false }
        
        // Check if player has all required resources in sufficient quantities
        let resourcesMatch = recipe.requiredResources.allSatisfy { requirement in
            let playerResourceCount = player.items.filter { $0.id == requirement.resourceId }.count
            return playerResourceCount >= requirement.count
        }
        
        return resourcesMatch
    }
    
    func checkCouldCraft(recipes: [Recipe], player: Player) -> [Recipe] {
        // Early exit if player has no items
        guard !player.items.isEmpty else { return [] }

        // Precompute item counts (O(n) - done once)
        let itemCounts = Dictionary(
            grouping: player.items,
            by: \.id
        ).mapValues { $0.count }

        // Filter recipes by level and resources (O(m * k), where m = recipes, k = requirements)
        return recipes.filter { recipe in
            // Check level first (cheapest check)
            guard player.smithingProgress.level >= recipe.professionLevel else {
                return false
            }

            // Check resources using precomputed counts
            return recipe.requiredResources.allSatisfy { requirement in
                itemCounts[requirement.resourceId, default: 0] >= requirement.count
            }
        }
    }
    
    
    func craft(recipeId: Int, player: Player) -> Item? {
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
