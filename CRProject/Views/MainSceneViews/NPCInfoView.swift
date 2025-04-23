//
//  SelectedNPCView 2.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 20.04.2025.
//


import SwiftUI

struct NPCInfoView: View {
    let npc: NPC?
    var onAction: (NPCAction) -> Void
    var player: Player = GameStateService.shared.player!
    
    var body: some View {
        HStack(spacing: 2) {
            VStack {
                // Desires
                HStack {
                    ZStack {
                        Circle()
                            .fill(Theme.bloodProgressColor)
                            .blur(radius: 7)
                            .opacity(0.3)
                        
                        Image(systemName: "drop.fill")
                            .font(Theme.smallFont)
                            .foregroundColor(Theme.bloodProgressColor)
                    }
                    .frame(width: 45, height: 45)
                    Text("Desires: ")
                        .font(Theme.smallFont)
                        .foregroundColor(Theme.bloodProgressColor)
                    
                    if player.desiredVictim.desiredSex != nil {
                        Text(player.desiredVictim.desiredSex?.rawValue ?? "")
                            .font(Theme.smallFont)
                            .foregroundColor(Theme.textColor)
                        Image(systemName: player.desiredVictim.desiredSex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.smallFont)
                            .foregroundColor(Color.yellow)
                    }
                    if player.desiredVictim.desiredAgeRange != nil {
                        Text("Age ")
                            .font(Theme.smallFont)
                            .foregroundColor(Theme.textColor)
                        Text((player.desiredVictim.desiredAgeRange?.rangeDescription ?? ""))
                            .font(Theme.smallFont)
                            .foregroundColor(Color.yellow)
                    }
                    if let desiredProfession = player.desiredVictim.desiredProfession {
                        Text(desiredProfession.rawValue)
                            .font(Theme.smallFont)
                            .foregroundColor(desiredProfession.color)
                        Image(systemName: desiredProfession.icon)
                            .font(Theme.smallFont)
                            .foregroundColor(desiredProfession.color)
                    }
                    
                    if let desiredMorality = player.desiredVictim.desiredMorality {
                        Text(desiredMorality.description)
                            .font(Theme.smallFont)
                            .foregroundColor(desiredMorality.color)
                        Image(systemName: desiredMorality.icon)
                            .font(Theme.smallFont)
                            .foregroundColor(desiredMorality.color)
                    }
                }
            }
            
        }
        .padding(.horizontal, 16)
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        )
    }
    
    private func getSpecialBehaviorProgress() -> String {
        return "\(Float(npc?.specialBehaviorTime ?? 0) / 4.0 * 100)%"
    }
}

private struct ActionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Theme.titleFont)
                .foregroundColor(color)
        }
    }
}
