import Combine

class DialogueManager: ObservableObject {
    static let shared = DialogueManager()
    @Published var isPresented = false
    @Published var currentNPC: NPC?
    @Published var player: Player?
    
    func startDialogue(with npc: NPC, player: Player) {
        currentNPC = npc
        self.player = player
        isPresented = true
    }
}
