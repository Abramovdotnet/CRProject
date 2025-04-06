import SwiftUI

struct SelectedNPCView: View {
    let npc: NPC
    var onAction: (NPCAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // NPC Icon and Status
            VStack(spacing: 4) {
                Image(systemName: npc.profession.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
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
                            .font(Theme.smallFont)
                            .foregroundColor(.white)
                    }
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(npc.isVampire ? "Vampire" : "Mortal")
                        .font(Theme.smallFont)
                        .foregroundColor(npc.isVampire ? .red : .white)
                }
                
                if !npc.isUnknown {
                    Text("\(npc.sex), \(npc.profession)")
                        .font(Theme.smallFont)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                if npc.isUnknown {
                    ActionButton(icon: "magnifyingglass") {
                        onAction(.investigate(npc))
                    }
                }
                
                if npc.isAlive {
                    ActionButton(icon: "bubble.left") {
                        onAction(.startConversation(npc))
                    }
                    
                    if !npc.isUnknown && !npc.isVampire {
                        ActionButton(icon: "drop.fill") {
                            onAction(.feed(npc))
                        }
                    }
                    
                    if !npc.isVampire {
                        ActionButton(icon: "bolt.fill") {
                            onAction(.drain(npc))
                        }
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
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
} 
