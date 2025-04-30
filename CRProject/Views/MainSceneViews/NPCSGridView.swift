import SwiftUICore
import SwiftUI
import CoreMotion // Import CoreMotion

struct NPCSGridView: View {
    let npcs: [NPC]
    @StateObject private var npcManager = NPCInteractionManager.shared
    @StateObject private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    var onAction: (NPCAction) -> Void
    
    @State private var isDragging = false
    @State private var scrollOffset: CGFloat = 0 // Track scroll position
    
    private struct NPCData: Identifiable {
        let npc: NPC
        let isSelected: Bool
        let isDisabled: Bool
        var id: Int { npc.index }
    }
    
    private func prepareNPCData() -> [NPCData] {
        var result: [NPCData] = []
        
        // Sort NPCs by lastPlayerInteractionDate (descending, handling optionals)
        let sortedNPCs = npcs
        
        // Take first 100 NPCs
        let maxNPCs = min(100, sortedNPCs.count)
        let limitedNPCs = Array(sortedNPCs[0..<maxNPCs])
        
        // Create NPCData for each NPC
        for npc in limitedNPCs {
            let isSelected: Bool = npcManager.selectedNPC?.id == npc.id
            let isDisabled: Bool = {
                guard let player = gameStateService.getPlayer() else { return false }
                guard npc.currentActivity != .followingPlayer else { return false }
                guard npc.currentActivity != .allyingPlayer else { return false }
                guard npc.currentActivity != .seductedByPlayer else { return false }
                return player.hiddenAt != .none
            }()
            
            let data = NPCData(
                npc: npc,
                isSelected: isSelected,
                isDisabled: isDisabled
            )
            result.append(data)
        }
        
        return result
    }
    
    // Add edge gradient mask
    private var edgeMask: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top fade
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                
                // Middle section
                Rectangle()
                    .fill(Color.black)
                
                // Bottom fade
                LinearGradient(
                    gradient: Gradient(colors: [.black, .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                // Background blur remains here
                blurredBackgroundEdges
                
                // Call the extracted ScrollView
                npcScrollView(proxy: proxy)
                    .mask(edgeMask)
            }
        }
    }
    
    // Extracted background blur view
    private var blurredBackgroundEdges: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.clear.opacity(0.7))
                .frame(width: 10)
                .blur(radius: 3)
            Spacer()
            Rectangle()
                .fill(Color.clear.opacity(0.7))
                .frame(width: 10)
                .blur(radius: 3)
        }
        .allowsHitTesting(false)
    }
    
    // Extracted ScrollView
    private func npcScrollView(proxy: ScrollViewProxy) -> some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Add spacer at the top to ensure proper initial positioning
                    Color.clear.frame(height: max(20, geometry.size.height / 2 - 160))
                    
                    ForEach(prepareNPCData()) { data in
                        NPCWidget(
                            npc: data.npc,
                            isSelected: data.isSelected,
                            isDisabled: data.isDisabled,
                            onTap: {
                                // First select the NPC
                                npcManager.select(with: data.npc)
                                
                                // Scroll to center with animation
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    proxy.scrollTo(data.id, anchor: .center)
                                }
                            },
                            onAction: onAction
                        )
                        .id(data.id)
                        .frame(height: 320)
                    }
                    
                    // Add spacer at the bottom to allow scrolling last item to center
                    Color.clear.frame(height: max(20, geometry.size.height / 2 - 160))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            .onAppear {
                // On appear, scroll to the selected NPC if exists, otherwise to the first NPC
                if let selectedNPC = npcManager.selectedNPC,
                   let selectedData = prepareNPCData().first(where: { $0.npc.id == selectedNPC.id }) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(selectedData.id, anchor: .center)
                    }
                } else if let firstNPC = prepareNPCData().first {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(firstNPC.id, anchor: .center)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
                .blur(radius: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: npcManager.lastInteractionActionTimestamp) { _ in 
            guard npcManager.lastInteractionActionTimestamp != nil,
                  let firstNPC = prepareNPCData().first else { return }
            
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(firstNPC.id, anchor: .center)
            }
        }
    }
}
