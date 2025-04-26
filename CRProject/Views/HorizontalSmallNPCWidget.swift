import SwiftUICore
import SwiftUI

struct HorizontalSmallNPCWidget: View {
    let npc: NPC
    @StateObject private var npcManager = NPCInteractionManager.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.7)
            
            VStack(alignment: .center) {
                HStack {
                    if !npc.isUnknown {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                Text(npc.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Image(systemName: npc.profession.icon)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)
                                Text(npc.profession.rawValue)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)
                            }
                            .padding(.horizontal, 5)
  
                        }
                        .padding(.horizontal, 5)
                    }
                }
    
                
            }
            .padding(5)
        }
        .frame(height: 25)
        .cornerRadius(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 2)
                .offset(y: 2)
        )
        .onChange(of: npcManager.npcStateChanged) { _ in
            // Force view update when NPC state changes
        }
    }
}
