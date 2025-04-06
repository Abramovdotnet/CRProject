import SwiftUI

struct SelectedNPCView: View {
    let npc: NPC
    var onAction: (NPCAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // NPC Icon and Status
            VStack(spacing: 4) {
                HStack {
                    if !npc.isUnknown {
                        Text("\(npc.sex.rawValue.capitalized), \(npc.profession)")
                            .font(Theme.smallFont)
                            .foregroundColor(npc.profession.color)
                        Image(systemName: npc.profession.icon)
                            .font(Theme.smallFont)
                            .foregroundColor(npc.profession.color)
                    }
                }
                
                if npc.isSleeping {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                }
            }
            .frame(width: 40)
            
            // NPC Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    
                    if !npc.isUnknown {
                        Text(npc.name)
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                    }
                    
                    Text("•")
                        .foregroundColor(.gray)
                                    
                    HStack {
                        Text("Status:")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)

                        Image(systemName: "waveform.path.ecg")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.isAlive ? .green : Theme.primaryColor)
                    }
                    
                    if !npc.isUnknown {
                        HStack {
                            Text(npc.isVampire ? "Vampire" : "Mortal")
                                .font(Theme.bodyFont)
                                .foregroundColor(npc.isVampire ? Theme.primaryColor : .green)
                        }
                    }
                }

            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
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
                        icon: "bubble.left",
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
                    }
                    
                    if !npc.isVampire {
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
        .padding(.horizontal)
        .frame(height: 55)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                .opacity(0.9)
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
                .font(.system(size: 18))
                .foregroundColor(color)
        }
    }
} 
