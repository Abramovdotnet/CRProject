import Foundation
import Combine

class NPCInteractionManager: ObservableObject {
    static let shared = NPCInteractionManager()
    
    @Published var selectedNPC: NPC?
    @Published var isShowingDialogue = false
    
    private init() {}
    
    func startConversation(with npc: NPC) {
        selectedNPC = npc
        isShowingDialogue = true
    }
    
    func select(with npc: NPC){
        selectedNPC = npc
    }
}
