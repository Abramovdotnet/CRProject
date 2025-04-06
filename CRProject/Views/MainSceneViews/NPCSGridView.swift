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
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: npc.isUnknown ? "questionmark.circle" : npc.profession.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                if !npc.isUnknown {
                    Text(npc.name)
                        .font(Theme.smallFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 50, height: 50)
            .padding(0)
            .background(isSelected ? Theme.accentColor.opacity(0.5) : Color.black.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
