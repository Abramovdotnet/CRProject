//
//  ItemReader.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import Foundation

class RecipeReader {
    static let shared = RecipeReader()
    private var recipes: [Recipe] = []
    
    private init() {
        loadRecipes()
    }
    
    private func loadRecipes() {
        guard let url = Bundle.main.url(forResource: "Smithing", withExtension: "json") else {
            print("Failed to find Smithing.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            recipes = try decoder.decode([Recipe].self, from: data)
        } catch {
            print("Error loading recipes: \(error)")
        }
    }
    
    func getRecipes() -> [Recipe] {
        return recipes
    }
    
    func getRecipe(by resultItemId: Int) -> Recipe? {
        return recipes.first { $0.resultItemId == resultItemId }
    }
    
    func getRecipes(for profession: Profession) -> [Recipe] {
        return recipes.filter { $0.profession == profession }
    }
}
