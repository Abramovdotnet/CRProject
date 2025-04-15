import SwiftUI

struct SelectedNPCView: View {
    let npc: NPC
    var onAction: (NPCAction) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Section: NPC Status
            VStack(alignment: .center, spacing: 4) {
                if !npc.isUnknown {
                    HStack(spacing: 4) {
                        Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                        
                        Image(systemName: npc.profession.icon)
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.profession.color)
                    }
                    .offset(y: -2)
                    
                    // Blood meter
                    HStack(spacing: 1) {
                        ForEach(0..<5) { index in
                            let segmentValue = Double(npc.bloodMeter.currentBlood) / 100.0
                            let segmentThreshold = Double(index + 1) / 5.0
                            
                            Rectangle()
                                .fill(segmentValue >= segmentThreshold ? 
                                      Theme.bloodProgressColor : Color.black.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                    .frame(width: 30)
                }
                
                // Status icons
                HStack(spacing: 4) {
                    if npc.currentActivity == .sleep {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(.blue)
                            .font(Theme.bodyFont)
                    }
                    if npc.isIntimidated {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Theme.bloodProgressColor)
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
                        
                        Text(npc.isUnknown ? "Unknown" : npc.isVampire ? "Vampire" : "Mortal")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.isVampire ? Theme.primaryColor : .green)
                    }
                }
            }
            
            Spacer()
            
            // Right Section: Action Buttons
            HStack(spacing: 10) {
                if npc.isUnknown {
                    ActionButton(
                        icon: "person.fill.questionmark",
                        action: {
                            onAction(.investigate(npc))
                            VibrationService.shared.lightTap()
                        },
                        color: Theme.textColor)
                }
                
                if npc.isAlive {
                    ActionButton(
                        icon: "bubble.left.fill",
                        action: {
                            onAction(.startConversation(npc))
                            VibrationService.shared.lightTap()
                        },
                        color: Theme.textColor)
                    
                    if !npc.isUnknown {
                        ActionButton(
                            icon: "moon.stars",
                            action: {
                                onAction(.startIntimidation(npc))
                                VibrationService.shared.lightTap()
                            },
                            color: .blue)
                    }
                    
                    if !npc.isVampire {
                        
                        if !npc.isUnknown {
                            ActionButton(
                                icon: "drop.halffull",
                                action: {
                                    onAction(.feed(npc))
                                    VibrationService.shared.regularTap()
                                },
                                color: Theme.primaryColor)
                        }
                        
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
                .fill(Color.black.opacity(0.7))
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
                .font(Theme.titleFont)
                .foregroundColor(color)
        }
    }
} 
