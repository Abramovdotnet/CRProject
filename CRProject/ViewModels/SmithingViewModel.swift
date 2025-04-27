import SwiftUI

class SmithingViewModel: ObservableObject {
    @Published var selectedRecipe: Recipe?
    @Published var craftingResult: String?
    @Published var isCrafting: Bool = false
    @Published var hasHammer: Bool = false
    @Published var availableRecipes: [Recipe] = []
    @Published var craftableRecipes: [Recipe] = []
    @Published private(set) var playerResources: [ItemGroup] = []
    @Published private(set) var playerTools: [ItemGroup] = []
    
    private let player: Player
    private let smithingSystem = SmithingSystem.shared
    
    init(player: Player) {
        self.player = player
        self.hasHammer = player.items.contains(where: { $0.id == 181 })
        updatePlayerItems()
        refreshRecipes()
    }
    
    func refreshRecipes() {
        availableRecipes = smithingSystem.getAvailableRecipes(player: player)
        craftableRecipes = smithingSystem.getCraftableRecipes(player: player)
        updatePlayerItems()
    }
    
    private func updatePlayerItems() {
        playerResources = Dictionary(grouping: player.items.filter { $0.type == .resource }, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
            
        playerTools = Dictionary(grouping: player.items.filter { $0.type == .tools }, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    func craftItem() {
        guard let recipe = selectedRecipe else { return }
        isCrafting = true
        
        let result = smithingSystem.craft(recipeId: recipe.resultItemId, player: player)
        craftingResult = "Crafted \(result?.name ?? "Unknown")"
        
        isCrafting = false
        
        refreshRecipes()
        updatePlayerItems()
        
        GameTimeService.shared.advanceTime()

        GameEventsBusService.shared.addMessageWithIcon(
            type: .common,
            location: GameStateService.shared.currentScene?.name ?? "Unknown",
            player: player,
            interactionType: NPCInteraction.workingOnSmithingOrder
        )
    }
    
    func selectRecipe(_ recipe: Recipe) {
        selectedRecipe = recipe
    }
    
    func clearResult() {
        craftingResult = nil
    }
} 
