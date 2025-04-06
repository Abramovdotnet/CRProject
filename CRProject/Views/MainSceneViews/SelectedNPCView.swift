import SwiftUI

struct SelectedNPCView: View {
    let npc: NPC
    var onAction: (NPCAction) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Section: NPC Status
            VStack(alignment: .center, spacing: 4) {
                HStack {
                    if !npc.isUnknown {
                        HStack(spacing: 4) {
                            Image(systemName: npc.sex == .female ? "figure.dress" : "figure.wave")
                                .font(Theme.bodyFont)
                                .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                            
                            Image(systemName: npc.profession.icon)
                                .font(Theme.bodyFont)
                                .foregroundColor(npc.profession.color)
                        }
                    }
                    if npc.isSleeping {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(.blue)
                            .font(Theme.bodyFont)
                    }
                }
            }
            .frame(width: 50)
            
            // Middle Section: NPC Info
            VStack(alignment: .leading, spacing: 4) {
                if !npc.isUnknown {
                    Text(npc.name)
                        .font(Theme.bodyFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    if !npc.isUnknown {
                        Text("\(npc.profession.rawValue)")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.profession.color)
                            .lineLimit(1)
                    }
                    
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.isAlive ? .green : Theme.primaryColor)
                        
                        Text(npc.isVampire ? "Vampire" : "Mortal")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.isVampire ? Theme.primaryColor : .green)
                    }
                }
            }
            
            Spacer()
            
            // Right Section: Action Buttons
            HStack(spacing: 20) {
                if npc.isUnknown {
                    ActionButton(
                        icon: "magnifyingglass",
                        action: {
                            onAction(.investigate(npc))
                            VibrationService.shared.lightTap()
                        },
                        color: Theme.primaryColor)
                }
                
                if npc.isAlive {
                    ActionButton(
                        icon: "bubble.left.fill",
                        action: {
                            onAction(.startConversation(npc))
                            VibrationService.shared.lightTap()
                        },
                        color: Theme.textColor)
                    
                    if !npc.isUnknown && !npc.isVampire {
                        ActionButton(
                            icon: "drop.halffull",
                            action: {
                                onAction(.feed(npc))
                                VibrationService.shared.regularTap()
                            },
                            color: Theme.primaryColor)
                        
                        ActionButton(
                            icon: "drop.fill",
                            action: {
                                onAction(.drain(npc))
                                VibrationService.shared.successVibration()
                            },
                            color: Theme.primaryColor)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        )
    }
}

private struct ActionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Theme.bodyFont)
                .foregroundColor(color)
        }
    }
} 
