//
//  ResourceRowView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import SwiftUI

struct ResourceRowView: View {
    let group: ItemGroup
    
    var body: some View {
        HStack {
            Image(systemName: group.icon)
                .foregroundColor(group.color)
                .font(Theme.bodyFont)
            
            Text(group.count > 1 ? "\(group.name) (\(group.count))" : group.name)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)
            
            Spacer()
        }
        .padding(.horizontal, 20)

    }
}
