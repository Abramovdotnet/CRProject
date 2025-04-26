//
//  RequiredResourcesView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import SwiftUI

struct RequiredResourcesView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Required Resources:")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)
            
            ForEach(recipe.requiredResources, id: \.resourceId) { resource in
                if let item = ItemReader.shared.getItem(by: resource.resourceId) {
                    HStack {
                        Image(systemName: item.icon())
                            .foregroundColor(item.color())
                            .font(Theme.smallFont)
                        Text("\(item.name) (x\(resource.count))")
                            .foregroundColor(Color.blue)
                            .font(Theme.smallFont)
                    }
                    .font(Theme.bodyFont)
                }
            }
            
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundColor(Theme.textColor)
                    .font(Theme.smallFont)
                Text("Blacksmith's Hammer")
                    .foregroundColor(Color.blue)
                    .font(Theme.smallFont)
            }
            .font(Theme.bodyFont)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
    }
}