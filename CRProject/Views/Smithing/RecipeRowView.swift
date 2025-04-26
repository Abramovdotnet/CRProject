//
//  RecipeRowView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    let isSelected: Bool
    let isCraftable: Bool
    
    var body: some View {
        if let resultItem = ItemReader.shared.getItem(by: recipe.resultItemId) {
            ZStack {
                VStack {
                    HStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(resultItem.color())
                                .blur(radius: 15)
                                .opacity(0.0)
                            
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            resultItem.color().opacity(0.3),
                                            Color.black.opacity(0.8)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: resultItem.icon())
                                .foregroundColor(resultItem.color())
                                .font(.system(size: 16))
                        }
                        .frame(width: 36, height: 36)
                        
                        Text(resultItem.name)
                            .foregroundColor(Theme.textColor)
                            .font(Theme.bodyFont)
                        
                        if !isCraftable {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                                .font(Theme.bodyFont)
                                .padding(.leading, 4)
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(Theme.bodyFont)
                                .padding(.leading, 4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Required Resources
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: ItemType.tools.icon)
                                        .foregroundColor(ItemType.tools.color)
                                        .font(Theme.smallFont)
                                    Text("Blacksmith's Hammer")
                                        .foregroundColor(Theme.textColor)
                                        .font(Theme.smallFont)
                                }
                                
                                ForEach(recipe.requiredResources, id: \.resourceId) { resource in
                                    if let item = ItemReader.shared.getItem(by: resource.resourceId) {
                                        HStack(spacing: 4) {
                                            Image(systemName: item.icon())
                                                .foregroundColor(item.color())
                                                .font(Theme.smallFont)
                                            Text("\(item.name) ×\(resource.count)")
                                                .font(Theme.smallFont)
                                                .foregroundColor(Theme.textColor)
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(resultItem.color().opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 10)
            .shadow(color: isSelected ? resultItem.color().opacity(0.8) : Color.clear, radius: 10)
        }
    }
}
