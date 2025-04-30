//
//  SelectedNPCView 2.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 20.04.2025.
//


import SwiftUI
import Combine

struct DesiresView: View {
    let npc: NPC?
    var onAction: (NPCAction) -> Void
    @ObservedObject var viewModel: MainSceneViewModel
    @ObservedObject var desiredVictim: DesiredVictim = GameStateService.shared.player!.desiredVictim
    
    // Set up a cancellable for notifications
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        HStack(spacing: 2) {
            VStack {
                // Desires
                HStack {
                    ZStack {
                        // 1. Frame (bottom layer)
                        Image("iconFrame")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20 * 1.1, height: 20 * 1.1)
                        
                        // 2. Background circle (middle layer)
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 20 * 0.85, height: 20 * 0.85)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Image("sphere1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20 * 0.8, height: 20 * 0.8)
                    }
                    .shadow(color: Theme.bloodProgressColor, radius: 3, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 20 * 1.4, height: 20 * 1.4)
                            .blur(radius: 4)
                            .opacity(0.7)
                    )
                    Text("Desires: ")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.bloodProgressColor)
                    
                    
                    if let desiredSex = desiredVictim.desiredSex {
                        Text(desiredSex.rawValue)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Image(systemName: desiredSex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.bodyFont)
                            .foregroundColor(Color.yellow)
                    }
                    if desiredVictim.desiredAgeRange != nil{
                        Text("Age ")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Text(desiredVictim.desiredAgeRange?.rangeDescription ?? "Unknown")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                    }
                    if let desiredProfession = desiredVictim.desiredProfession {
                        Text(desiredProfession.rawValue)
                            .font(Theme.bodyFont)
                            .foregroundColor(desiredProfession.color)
                        Image(systemName: desiredProfession.icon)
                            .font(Theme.bodyFont)
                            .foregroundColor(desiredProfession.color)
                    }
                    
                    if let desiredMorality = desiredVictim.desiredMorality {
                        Text(desiredMorality.description)
                            .font(Theme.bodyFont)
                            .foregroundColor(desiredMorality.color)
                        Image(systemName: desiredMorality.icon)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
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
