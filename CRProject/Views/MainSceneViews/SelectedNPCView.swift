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
