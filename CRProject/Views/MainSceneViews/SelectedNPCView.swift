import SwiftUI

struct SelectedNPCView: View {
    let npc: NPC
    var onAction: (NPCAction) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                // Action Buttons
                HStack(spacing: 6) {
                    if !npc.isUnknown {
                        HStack {
                            Spacer()
                            ZStack {
                                VStack(spacing: 4) {
                                    HStack(alignment: .center) {
                                        Spacer()
                                        Image(systemName: npc.currentActivity.icon)
                                            .foregroundColor(npc.currentActivity.color)
                                            .font(Theme.smallFont)
                                            .padding(.leading, 3)
                                        GradientProgressBar(value: Float(Float(npc.specialBehaviorTime) / 4.0 * 100), barColor: npc.currentActivity.color, backgroundColor: Theme.textColor.opacity(0.3))
                                            .frame(width: 50, height: 5)
                                            .shadow(color: Color.green.opacity(0.3), radius: 2)
                                            .padding(.leading, -5)
                                        Text(getSpecialBehaviorProgress())
                                            .font(Theme.smallFont)
                                            .foregroundColor(Theme.bloodProgressColor)
                                    }
                                }
                            }
                            .frame(width: 120, height: 15)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.7))
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            )
                            .padding(.top, 1)
                            Spacer()
                        }
                        .padding(.top, -3)
                    }
                    Spacer()
                    Text(npc.morality)
                        .font(Theme.smallFont)
                        .foregroundColor(Theme.textColor)
                    
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
                Text(npc.background)
                    .font(Theme.smallFont)
                    .foregroundColor(Theme.textColor)
            }
            
        }
        .padding(.horizontal, 16)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        )
    }
    
    private func getSpecialBehaviorProgress() -> String {
        return "\(Float(npc.specialBehaviorTime) / 4.0 * 100)%"
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
