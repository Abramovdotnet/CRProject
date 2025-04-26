//
//  InteractionIconView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import Combine
import SwiftUI
import SwiftUICore
import Foundation

struct InteractionIconView: View {
    let type: NPCInteraction
    let hasSuccess: Bool
    let isSuccess: Bool?
    
    var body: some View {
        HStack(spacing: 4) {
            if hasSuccess {
                Text("[\(isSuccess == true ? "Successfuly" : "Unsuccessfuly")] ")
                    .font(Theme.bodyFont)
                    .foregroundColor(isSuccess == true ? Color.green : Color.red)
                +
                Text(Image(systemName: type.icon))
                    .font(Theme.bodyFont)
                    .foregroundColor(type.color)
                +
                Text(" [\(type.description.capitalized)]")
                    .font(Theme.bodyFont)
                    .foregroundColor(type.color)
            } else {
                Text(Image(systemName: type.icon))
                    .font(Theme.bodyFont)
                    .foregroundColor(type.color)
                +
                Text(" [\(type.description.capitalized)]")
                    .font(Theme.bodyFont)
                    .foregroundColor(type.color)
            }
        }
        .font(Theme.bodyFont)
    }
}