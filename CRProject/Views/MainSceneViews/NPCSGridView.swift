import SwiftUICore
import SwiftUI

struct NPCSGridView: View {
    let npcs: [NPC]
    @StateObject private var npcManager = NPCInteractionManager.shared
    var onAction: (NPCAction) -> Void
    
    // Fixed 6-column grid configuration
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 24), count: 6)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(npcs.prefix(20)) { npc in
                    NPCGridButton(
                        npc: npc,
                        isSelected: npcManager.currentNPC?.id == npc.id
                    ) {
                        if npcManager.currentNPC?.id == npc.id {
                            onAction(.startConversation(npc))
                        } else {
                            npcManager.select(with: npc)
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}

struct NPCGridButton: View {
    let npc: NPC
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            VibrationService.shared.lightTap()
            onTap()
        }) {
            VStack(spacing: 4) {
                Image(systemName: npc.isUnknown ? "questionmark.circle" : "waveform.path.ecg")
                    .font(.system(size: 16))
                    .foregroundColor(iconColor())
                
                if !npc.isUnknown {
                    HStack {
                        Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.stand.dress")
                            .font(Theme.smallFont)
                            .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                            .lineLimit(1)
                        Image(systemName: npc.profession.icon)
                            .font(Theme.smallFont)
                            .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 50, height: 50)
            .padding(0)
            .background(isSelected ? Theme.accentColor.opacity(0.5) : Color.black.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(npc.isAlive ? 1 : 0.7)
    }
    
    func iconColor() -> Color {
        if npc.isAlive {
            if isSelected {
                return Theme.textColor
            } else {
                return npc.isUnknown ? .white : npc.isVampire ? Theme.primaryColor : .green
            }
        } else {
            return Theme.primaryColor
        }
    }
}
