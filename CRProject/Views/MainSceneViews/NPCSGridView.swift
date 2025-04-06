import SwiftUICore
import SwiftUI

class NPCSelection {
    var id: UUID?
}

struct NPCSGridView: View {
    let npcs: [NPC]
    let selectedNPC: NPCSelection = NPCSelection()
    
    var onAction: (NPCAction) -> Void
    // Конфигурация сетки
    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 80), spacing: 10),
        GridItem(.adaptive(minimum: 50, maximum: 80), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(npcs.prefix(20)) { npc in
                    NPCGridButton(
                        npc: npc,
                        isSelected: selectedNPC.id == npc.id
                    ) {
                        if selectedNPC.id == npc.id {
                             onAction(.startConversation(npc))
                        } else {
                            selectedNPC.id = npc.id
                        }
                    }
                }
            }
            .padding()
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
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                if !npc.isUnknown {
                    Text(npc.name)
                        .font(Theme.bodyFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 40, height: 40)
            .padding(8)
            .background(isSelected ? Theme.accentColor.opacity(0.5) : Color.black.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
