import Foundation
import SwiftUI

class DebugViewViewModel: ObservableObject {
    @Published var player: Player
    @Published var npcs: [NPC]
    @Published var currentScene: Scene
    @Published var gameTime: GameTime
    @Published var debugPrompts: [String] = []
    
    // Add observable blood meter values
    @Published var playerBloodPercentage: Float = 0
    @Published var npcBloodPercentages: [UUID: Float] = [:]
    
    private let feedingService: FeedingService
    private let bloodService: BloodManagementService
    
    init() {
        // Initialize services first
        self.feedingService = DependencyManager.shared.resolve()
        self.bloodService = DependencyManager.shared.resolve()
        self.gameTime = DependencyManager.shared.resolve()
        
        // Create player
        let createdPlayer = Player(name: "Vampire Lord", sex: .male, age: 300, profession: "Vampire")
        self.player = createdPlayer
        self.playerBloodPercentage = createdPlayer.bloodMeter.bloodPercentage
        
        // Create NPCs
        let createdNPCs = DebugViewViewModel.createNPCs()
        self.npcs = createdNPCs
        
        // Create scene
        let scene = SceneBuilder()
            .withName("Town Square")
            .withCharacter(createdPlayer)
            .withCharacters(createdNPCs)
            .build()
        self.currentScene = scene
        
        // Initialize NPC blood percentages
        for npc in createdNPCs {
            self.npcBloodPercentages[npc.id] = npc.bloodMeter.bloodPercentage
        }
        
        
        // Add debug prompt after all properties are initialized
        DispatchQueue.main.async {
            self.addDebugPrompt("Scene created: \(scene.name)")
        }
    }
    
    private static func createNPCs() -> [NPC] {
        return [
            NPCBuilder()
                .name("John Smith")
                .sex(.male)
                .age(35)
                .profession("Merchant")
                .build(),
            NPCBuilder()
                .name("Sarah Johnson")
                .sex(.female)
                .age(28)
                .profession("Nurse")
                .build(),
            NPCBuilder()
                .name("Michael Brown")
                .sex(.male)
                .age(42)
                .profession("Guard")
                .build()
        ]
    }
    
    func respawnNPCs() {
        let newNPCs = DebugViewViewModel.createNPCs()
        self.npcs = newNPCs
        
        // Update scene with new NPCs
        currentScene.setCharacters([player] + newNPCs)
        
        // Reset blood percentages
        npcBloodPercentages.removeAll()
        for npc in newNPCs {
            self.npcBloodPercentages[npc.id] = npc.bloodMeter.bloodPercentage
        }
        
        addDebugPrompt("NPCs respawned")
    }
    
    func feedOnNPC(_ npc: NPC) {
        do {
            try feedingService.feedOnCharacter(vampire: player, prey: npc, amount: 20.0)
            
            self.playerBloodPercentage = player.bloodMeter.bloodPercentage
            self.npcBloodPercentages[npc.id] = npc.bloodMeter.bloodPercentage
            
            addDebugPrompt("Player fed on \(npc.name)")
        } catch {
            addDebugPrompt("Failed to feed: \(error.localizedDescription)")
        }
    }
    
    private func addDebugPrompt(_ message: String) {
        debugPrompts.insert(message, at: 0)
        if debugPrompts.count > 10 {
            debugPrompts.removeLast()
        }
    }
} 
