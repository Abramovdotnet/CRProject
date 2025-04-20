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
        GeometryReader { geometry in
            HStack(spacing: 2) {
                VStack {
                    // Desires
                    HStack {
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
                        
                        if let desiredMotivation = player.desiredVictim.desiredMotivation {
                            Text(desiredMotivation.description)
                                .font(Theme.smallFont)
                                .foregroundColor(desiredMotivation.color)
                            Image(systemName: desiredMotivation.icon)
                                .font(Theme.smallFont)
                                .foregroundColor(desiredMotivation.color)
                        }
                    }
                    if let npc = npc {
                        // Character info
                        HStack(spacing: 6) {
                            if !npc.isUnknown {
                                Text(npc.name)
                                    .font(Theme.smallFont)
                                    .foregroundColor(Theme.textColor)
                                Image(systemName: npc.currentActivity.icon)
                                    .foregroundColor(npc.currentActivity.color)
                                    .font(Theme.smallFont)
                                    .padding(.leading, 3)
                                Text(npc.currentActivity.description)
                                    .font(Theme.smallFont)
                                    .foregroundColor(npc.currentActivity.color)
                                
                                if npc.isSpecialBehaviorSet {
                                    Text(getSpecialBehaviorProgress())
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.bloodProgressColor)
                                }
                            }
                            Image(systemName: npc.morality.icon)
                                .font(Theme.smallFont)
                                .foregroundColor(npc.morality.color)
                            Text(npc.morality.description)
                                .font(Theme.smallFont)
                                .foregroundColor(npc.morality.color)
                            Image(systemName: npc.motivation.icon)
                                .font(Theme.smallFont)
                                .foregroundColor(npc.motivation.color)
                            Text(npc.motivation.description)
                                .font(Theme.smallFont)
                                .foregroundColor(npc.motivation.color)
                        }
                        .padding(.top, 5)
                    }
                    
                }
                
            }
            .padding(.horizontal, 16)
            .frame(width: geometry.size.width, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            )
        }
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
