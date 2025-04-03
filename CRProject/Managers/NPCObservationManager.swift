import Combine

class NPCObservationManager: ObservableObject {
    static let shared = NPCObservationManager()
    @Published var isPresented = false
    @Published var currentNPC: NPC?
    
    func setReference(with npc: NPC) {
        currentNPC = npc
        isPresented = true
    }
}
