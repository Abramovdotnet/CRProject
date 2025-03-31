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
    @Published var sceneAwareness: Float = 0
    
    private let feedingService: FeedingService
    private let bloodService: BloodManagementService
    private let vampireNatureRevealService: VampireNatureRevealService
    
    init() {
        // Initialize services first
        self.gameTime = DependencyManager.shared.resolve()
        self.vampireNatureRevealService = DependencyManager.shared.resolve()
        self.bloodService = DependencyManager.shared.resolve()
        self.feedingService = DependencyManager.shared.resolve()
        
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
        
        // Initialize scene awareness
        self.sceneAwareness = vampireNatureRevealService.getAwareness(for: scene.id)
        
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
            try feedingService.feedOnCharacter(vampire: player, prey: npc, amount: 30.0, in: currentScene.id)
            
            self.playerBloodPercentage = player.bloodMeter.bloodPercentage
            self.npcBloodPercentages[npc.id] = npc.bloodMeter.bloodPercentage
            self.sceneAwareness = vampireNatureRevealService.getAwareness(for: currentScene.id)
            
            addDebugPrompt("Player fed on \(npc.name)")
        } catch {
            addDebugPrompt("Failed to feed: \(error.localizedDescription)")
        }
    }
    
    func emptyNPCBlood(_ npc: NPC) {
        do {
            try feedingService.emptyBlood(vampire: player, prey: npc, in: currentScene.id)
            
            self.playerBloodPercentage = player.bloodMeter.bloodPercentage
            self.npcBloodPercentages[npc.id] = npc.bloodMeter.bloodPercentage
            self.sceneAwareness = vampireNatureRevealService.getAwareness(for: currentScene.id)
            
            addDebugPrompt("Player emptied blood of \(npc.name)")
        } catch {
            addDebugPrompt("Failed to empty blood: \(error.localizedDescription)")
        }
    }
    
    private func addDebugPrompt(_ message: String) {
        debugPrompts.insert(message, at: 0)
        if debugPrompts.count > 10 {
            debugPrompts.removeLast()
        }
    }
} 
