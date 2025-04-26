//
//  NPCIconView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import Combine
import SwiftUI
import SwiftUICore
import Foundation

struct NPCIconView: View {
    let npc: NPC
    
    var body: some View {
        HStack(spacing: 4) {
            Text(npc.name)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)
        }
    }
}