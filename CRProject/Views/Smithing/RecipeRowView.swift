//
//  RecipeRowView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//

import SwiftUI

struct RecipeRowView: View {
    @ObservedObject var recipe: Recipe
    let isSelected: Bool
    let isCraftable: Bool
    
    var body: some View {
        if let resultItem = ItemReader.shared.getItem(by: recipe.resultItemId) {
            ZStack {
                VStack {
                    ZStack {
                        VStack {
                            HStack(spacing: 12) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(isCraftable ? resultItem.color() : Theme.textColor)
                                        .blur(radius: 15)
                                        .opacity(0.0)
                                    
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    isCraftable ? resultItem.color().opacity(0.3) : Theme.textColor.opacity(0.3),
                                                    Color.black.opacity(0.8)
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 25
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: resultItem.icon())
                                        .foregroundColor(isCraftable ? resultItem.color() : Theme.textColor)
                                        .font(.system(size: 16))
                                }
                                .frame(width: 36, height: 36)
                                
                                Text(resultItem.name)
                                    .foregroundColor(Theme.textColor)
                                    .font(Theme.bodyFont)
                                
                                Spacer()
                                
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
                                                    Text("\(item.name) \(resource.count)/\(resource.availableCount)")
                                                        .font(Theme.smallFont)
                                                        .foregroundColor(Theme.textColor)
                                                }
                                            }
                                        }
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .foregroundColor(Theme.textColor)
                                                .font(Theme.smallFont)
                                            Text("Production Time: \(recipe.productionTime) hours")
                                                .foregroundColor(Theme.textColor)
                                                .font(Theme.smallFont)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                  
                        HStack {
                            Spacer()
                            VStack {
                                Text("Mastery Level: \(recipe.professionLevel)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Color.green)
                                Spacer()
                            }
                        }
                  
                    }
                    .frame(height: 150)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCraftable ? resultItem.color().opacity(0.3) : Theme.textColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .shadow(color: isSelected ? isCraftable ? resultItem.color().opacity(0.8) : Color.white.opacity(0.3) : Color.clear, radius: 10)
        }
    }
}
