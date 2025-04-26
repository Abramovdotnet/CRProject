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
                Image(systemName: resultItem.icon())
                    .font(.system(size: 50))
                    .foregroundColor(resultItem.color())
                    .frame(width: 80, height: 80)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                
                Text(resultItem.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                
                Button(action: onCraft) {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Text("Craft")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                    }
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.primaryColor, lineWidth: 1)
                    )
                }
                .disabled(isCrafting)
            }
        }
    }
}