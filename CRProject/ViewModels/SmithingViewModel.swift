import SwiftUI

class SmithingViewModel: ObservableObject {
    @Published var selectedRecipe: Recipe?
    @Published var craftingResult: String?
    @Published var isCrafting: Bool = false
    
    private let player: Player
    private let smithingSystem = SmithingSystem.shared
    
    init(player: Player) {
        self.player = player
    }
    
    var availableRecipes: [Recipe] {
        smithingSystem.getAvailableRecipes(player: player)
    }
    
    var craftableRecipes: [Recipe] {
        smithingSystem.getCraftableRecipes(player: player)
    }
    
    var playerResources: [ItemGroup] {
        Dictionary(grouping: player.items.filter { $0.type == .resource }, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    func craftItem() {
        guard let recipe = selectedRecipe else { return }
        isCrafting = true
        
        let (_, message) = smithingSystem.attemptCraft(recipeId: recipe.resultItemId, player: player)
        craftingResult = message
        
        isCrafting = false
        let isSuccess = craftingResult?.contains("Successfully")
        
        GameTimeService.shared.advanceTime()
        
        if craftingResult?.contains("Successfully") == true {
            GameEventsBusService.shared.addMessageWithIcon(
                type: .common,
                location: GameStateService.shared.currentScene?.name ?? "Unknown",
                player: player,
                interactionType: NPCInteraction.workingOnSmithingOrder
            )
        }
    }
    
    func selectRecipe(_ recipe: Recipe) {
        selectedRecipe = recipe
    }
    
    func clearResult() {
        craftingResult = nil
    }
} 
