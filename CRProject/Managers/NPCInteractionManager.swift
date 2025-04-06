import Foundation
import Combine

class NPCInteractionManager: ObservableObject {
    static let shared = NPCInteractionManager()
    
    @Published var currentNPC: NPC?
    @Published var isShowingDialogue = false
    
    private init() {}
    
    func startConversation(with npc: NPC) {
        currentNPC = npc
        isShowingDialogue = true
    }
    
    func select(with npc: NPC){
        currentNPC = npc
    }
}
