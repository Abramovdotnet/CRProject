//
//  SmithingSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 25.04.2025.
//

import UIKit

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
        let craftableRecipes = checkCouldCraft(recipes: allRecipes, player: player)
        
        // Calculate available counts for craftable recipes
        let itemCounts = Dictionary(
            grouping: player.items,
            by: \.id
        ).mapValues { $0.count }
        
        // Create new RecipeResource objects with updated counts
        craftableRecipes.forEach { recipe in
            recipe.requiredResources = recipe.requiredResources.map { resource in
                let newResource = RecipeResource(resourceId: resource.resourceId, count: resource.count)
                newResource.availableCount = itemCounts[resource.resourceId, default: 0]
                return newResource
            }
        }
        
        return craftableRecipes
    }
    
    func getAvailableRecipes(player: Player) -> [Recipe] {
        let recipes = RecipeReader.shared.getRecipes().filter { $0.professionLevel <= player.smithingProgress.level }
        // Calculate available counts for all recipes
        let itemCounts = Dictionary(
            grouping: player.items,
            by: \.id
        ).mapValues { $0.count }
        
        // Create new RecipeResource objects with updated counts
        recipes.forEach { recipe in
            recipe.requiredResources = recipe.requiredResources.map { resource in
                let newResource = RecipeResource(resourceId: resource.resourceId, count: resource.count)
                newResource.availableCount = itemCounts[resource.resourceId, default: 0]
                return newResource
            }
        }
        
        return recipes
    }
    
    func checkCouldCraft(recipe: Recipe, player: Player) -> Bool {
        guard player.smithingProgress.level >= recipe.professionLevel else { return false }
        guard !recipe.isUnknown else { return false }
        
        // Precompute item counts for efficiency
        let itemCounts = Dictionary(
            grouping: player.items,
            by: \.id
        ).mapValues { $0.count }
        
        // Check if player has all required resources in sufficient quantities
        let resourcesMatch = recipe.requiredResources.allSatisfy { requirement in
            let availableCount = itemCounts[requirement.resourceId, default: 0]
            requirement.availableCount = availableCount
            return availableCount >= requirement.count
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
                let availableCount = itemCounts[requirement.resourceId, default: 0]
                requirement.availableCount = availableCount
                return availableCount >= requirement.count
            }
        }
    }
    
    func unlockNewRecipe(player: Player) {
        let firstUnknownRecipe = RecipeReader.shared.getRecipes()
            .filter { $0.isUnknown == true }
            .sorted { $0.professionLevel < $1.professionLevel }
            .first
        
        if firstUnknownRecipe?.professionLevel ?? 0 > player.smithingProgress.level {
            player.smithingProgress.level += 1
            
            UIKitPopUpManager.shared.show(title: "New smithing level unlocked", description: "You have reached a new smithing level!", icon: UIImage(systemName: Ability.smithingNovice.icon))

        }
        
        if firstUnknownRecipe != nil {
            firstUnknownRecipe?.isUnknown = false
        }
    }
    
    func craft(recipeId: Int, player: Player) -> (Item?, Bool) {
        let recipe = RecipeReader.shared.getRecipe(by: recipeId)!
        var result: Item?
        var newRecipeUnlocked: Bool = false
        
        if checkCouldCraft(recipe: recipe, player: player) {
            for resource in recipe.requiredResources {
                for _ in 0..<resource.count {
                    ItemsManagementService.shared.removeFirstItemById(id: resource.resourceId, from: player)
                }
            }
            
            result = Item.createUnique(ItemReader.shared.getItem(by: recipe.resultItemId)!)
            
            if recipe.professionLevel == player.smithingProgress.level || RecipeReader.shared.getRecipes()
                .filter({ $0.professionLevel < player.smithingProgress.level && $0.isUnknown == false }).count > 0 {
                newRecipeUnlocked = Int.random(in: 1...4) == 4
                
                if newRecipeUnlocked {
                    unlockNewRecipe(player: player)
                    StatisticsService.shared.increaseSmithingRecipesUnlocked()
                }
            }
        }
        
        return (result, newRecipeUnlocked)
    }
}
