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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: resultItem.icon())
                        .foregroundColor(resultItem.color())
                        .font(Theme.bodyFont)
                    
                    Text(resultItem.name)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                    
                    Spacer()
                    
                    if !isCraftable {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                            .font(Theme.bodyFont)
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(Theme.bodyFont)
                    }
                }
                
                // Required Resources
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(Theme.textColor)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.awarenessProgressColor.opacity(0.3) : Color.clear)
            )
        }
    }
}
