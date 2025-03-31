import Foundation
import SwiftUI

class DebugViewViewModel: ObservableObject {
    @Published var player: Player
    @Published var npcs: [NPC]
    @Published var currentScene: Scene
    @Published var gameTime: GameTimeService
    @Published var debugPrompts: [String] = []
    
    // Add observable blood meter values
    @Published var playerBloodPercentage: Float = 0
    @Published var npcBloodPercentages: [UUID: Float] = [:]
    @Published var sceneAwareness: Float = 0
    
    let statisticsService: StatisticsService
    let feedingService: FeedingService
    let bloodService: BloodManagementService
    let vampireNatureRevealService: VampireNatureRevealService
    let investigationService: InvestigationService
    
    init() {
        // Initialize services first
        self.statisticsService = DependencyManager.shared.resolve()
        self.gameTime = DependencyManager.shared.resolve()
        self.vampireNatureRevealService = DependencyManager.shared.resolve()
        self.bloodService = DependencyManager.shared.resolve()
        self.feedingService = DependencyManager.shared.resolve()
        self.investigationService = DependencyManager.shared.resolve()
        
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
        let professions = ["Farmer", "Merchant", "Guard", "Blacksmith", "Innkeeper", "Priest", "Scholar", "Hunter"]
        return (0..<8).map { index in
            NPCBuilder()
                .name("NPC \(Int.random(in: 1...1000))")
                .sex(Bool.random() ? .male : .female)
                .age(Int.random(in: 18...80))
                .profession(professions[index])
                .build()
        }
    }
    
    func canInvestigateNPC(_ npc: NPC) -> Bool {
        return investigationService.canInvestigate(inspector: player, investigationObject: npc)
    }
    
    func respawnNPCs() {
        // Clear existing NPCs
        npcs.removeAll()
        npcBloodPercentages.removeAll()
        
        // Create new NPCs with random properties
        let npcCount = 8 // Increased from 5 to 8
        for _ in 0..<npcCount {
            let npc = NPC(
                name: "NPC \(Int.random(in: 1...1000))",
                sex: Bool.random() ? .male : .female,
                age: Int.random(in: 18...80),
                profession: ["Farmer", "Merchant", "Guard", "Blacksmith", "Innkeeper", "Priest", "Scholar", "Hunter"].randomElement() ?? "Citizen"
            )
            npcs.append(npc)
            npcBloodPercentages[npc.id] = npc.bloodMeter.bloodPercentage
        }
        
        addDebugPrompt("Respawned \(npcCount) NPCs")
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
    
    func resetAwareness() {
        vampireNatureRevealService.decreaseAwareness(for: currentScene.id, amount: 100.0)
        self.sceneAwareness = vampireNatureRevealService.getAwareness(for: currentScene.id)
        addDebugPrompt("Awareness reset to minimum")
    }
    
    func investigateNPC(_ npc: NPC) {
        investigationService.investigate(inspector: player, investigationObject: npc)
        self.playerBloodPercentage = player.bloodMeter.bloodPercentage
        addDebugPrompt("Player investigated \(npc.name)")
    }
    
    private func addDebugPrompt(_ message: String) {
        debugPrompts.insert(message, at: 0)
        if debugPrompts.count > 10 {
            debugPrompts.removeLast()
        }
    }
} 
