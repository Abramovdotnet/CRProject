import Combine
import Foundation

class NPCInteractionManager: ObservableObject {
    static let shared = NPCInteractionManager()
    
    @Published var selectedNPC: NPC?
    @Published var isShowingDialogue = false
    @Published var lastInteractionActionTimestamp: Date? // Timestamp for actual interactions
    @Published var npcStateChanged = false // Add publisher for NPC state changes
    
    private init() {}
    
    func startConversation(with npc: NPC) {
        // Select NPC and update interaction state
        select(with: npc) 
        isShowingDialogue = true
    }
    
    func select(with npc: NPC){
        // Only select, don't trigger interaction timestamp update
        selectedNPC = npc
    }
    
    // Call this after any action that should re-sort the grid
    func playerInteracted(with npc: NPC) {
        npc.lastPlayerInteractionDate = Date()
        lastInteractionActionTimestamp = Date() // Update timestamp to trigger scroll
        // npcStateChanged.toggle() // Temporarily commented out for debugging
    }
}
