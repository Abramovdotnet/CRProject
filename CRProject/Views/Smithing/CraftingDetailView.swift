//
//  CraftingDetailView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import SwiftUI

struct CraftingDetailView: View {
    let recipe: Recipe
    let isCrafting: Bool
    let onCraft: () -> Void
    
    var body: some View {
        if let resultItem = ItemReader.shared.getItem(by: recipe.resultItemId) {
            VStack(spacing: 12) {
                RecipeRowView(
                    recipe: recipe,
                    isSelected: true,
                    isCraftable: couldCraft()
                )
                .padding(.horizontal, 6)
                .opacity(couldCraft() ? 1 : 0.7)
                
                if couldCraft() {
                    Button(action: onCraft) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .blur(radius: 15)
                                    .opacity(0.0)
                                
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color.green.opacity(0.3),
                                                Color.black.opacity(0.8)
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 25
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "hammer.fill")
                                    .foregroundColor(Color.green)
                                    .font(.system(size: 16))
                            }
                            .frame(width: 36, height: 36)
                        }
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(12)
                    }
                    .frame(width: 150)
                    .shadow(color: Color.green, radius: 10)
                }
            }
        }
    }
    
    func couldCraft() -> Bool {
        return SmithingSystem.shared.checkCouldCraft(recipe: recipe, player: GameStateService.shared.player!)
    }
}
