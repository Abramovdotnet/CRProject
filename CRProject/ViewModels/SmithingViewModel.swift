import SwiftUI

class SmithingViewModel: ObservableObject {
    @Published var selectedRecipe: Recipe?
    @Published var craftingResult: String?
    @Published var isCrafting: Bool = false
    @Published var hasHammer: Bool = false
    @Published var availableRecipes: [Recipe] = []
    @Published var craftableRecipes: [Recipe] = []
    @Published var selectedProfessionLevel: Int? = nil
    @Published var selectedItemType: ItemType? = nil
    @Published private(set) var playerResources: [ItemGroup] = []
    @Published private(set) var playerTools: [ItemGroup] = []
    
    private let player: Player
    private let smithingSystem = SmithingSystem.shared
    private let itemReader = ItemReader.shared
    
    init(player: Player) {
        self.player = player
        self.hasHammer = player.items.contains(where: { $0.id == 181 })
        updatePlayerItems()
        refreshRecipes()
    }
    
    func refreshRecipes() {
        let allAvailableRecipes = smithingSystem.getAvailableRecipes(player: player)
        let allCraftableRecipes = smithingSystem.getCraftableRecipes(player: player)
        
        // Apply filters if selected
        availableRecipes = filterRecipes(allAvailableRecipes)
        craftableRecipes = filterRecipes(allCraftableRecipes)
        
        updatePlayerItems()
    }
    
    private func filterRecipes(_ recipes: [Recipe]) -> [Recipe] {
        var filteredRecipes = recipes
        
        // Filter by profession level if selected
        if let level = selectedProfessionLevel {
            filteredRecipes = filteredRecipes.filter { $0.professionLevel == level }
        }
        
        // Filter by item type if selected
        if let type = selectedItemType {
            filteredRecipes = filteredRecipes.filter { recipe in
                if let item = itemReader.getItem(by: recipe.resultItemId) {
                    return item.type == type
                }
                return false
            }
        }
        
        return filteredRecipes
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
        ItemsManagementService.shared.giveItem(item: result!, to: player)
        craftingResult = "Crafted \(result?.name ?? "Unknown")"
        
        isCrafting = false
        
        refreshRecipes()
        updatePlayerItems()
        
        GameTimeService.shared.advanceHours(hours: recipe.productionTime)

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
