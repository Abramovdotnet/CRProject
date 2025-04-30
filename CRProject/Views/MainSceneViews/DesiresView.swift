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
    
    // State for tracking current desires to force view updates
    @State private var desiredSex: Sex? = nil
    @State private var desiredAgeRange: String? = nil
    @State private var desiredProfession: Profession? = nil
    @State private var desiredMorality: Morality? = nil
    
    // Set up a cancellable for notifications
    @State private var cancellables = Set<AnyCancellable>()
    
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
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.bloodProgressColor)
                    }
                    .frame(width: 25, height: 25)
                    Text("Desires: ")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.bloodProgressColor)
                    
                    if let desiredSex = viewModel.desiredSex {
                        Text(desiredSex.rawValue)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Image(systemName: desiredSex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.bodyFont)
                            .foregroundColor(Color.yellow)
                    }
                    if let desiredAge = viewModel.desiredAge {
                        Text("Age ")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Text(desiredAge)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                    }
                    if let desiredProfession = viewModel.desiredProfession {
                        Text(desiredProfession.rawValue)
                            .font(Theme.bodyFont)
                            .foregroundColor(desiredProfession.color)
                        Image(systemName: desiredProfession.icon)
                            .font(Theme.bodyFont)
                            .foregroundColor(desiredProfession.color)
                    }
                    
                    if let desiredMorality = viewModel.desiredMorality {
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
        .onAppear {
            setupDesireUpdates()
        }
        .onChange(of: viewModel.desiredSex) { _ in updateLocalState() }
        .onChange(of: viewModel.desiredAge) { _ in updateLocalState() }
        .onChange(of: viewModel.desiredProfession) { _ in updateLocalState() }
        .onChange(of: viewModel.desiredMorality) { _ in updateLocalState() }
    }
    
    private func setupDesireUpdates() {
        updateLocalState()
        
        // Listen for desire reset notifications
        NotificationCenter.default.publisher(for: .desireReset)
            .receive(on: RunLoop.main)
            .sink { _ in
                updateLocalState()
            }
            .store(in: &cancellables)
    }
    
    private func updateLocalState() {
        // Update our local state with the viewModel values
        desiredSex = viewModel.desiredSex
        desiredAgeRange = viewModel.desiredAge
        desiredProfession = viewModel.desiredProfession
        desiredMorality = viewModel.desiredMorality
    }
    
    private func getSpecialBehaviorProgress() -> String {
        return "\(Float(npc?.specialBehaviorTime ?? 0) / 4.0 * 100)%"
    }
}

// Notification for desire resets
extension Notification.Name {
    static let desireReset = Notification.Name("desireReset")
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
