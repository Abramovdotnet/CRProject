import SwiftUI

// MARK: - Main View
struct SmithingView: View {
    @StateObject private var viewModel: SmithingViewModel
    @StateObject private var mainViewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(player: Player, mainViewModel: MainSceneViewModel) {
        _viewModel = StateObject(wrappedValue: SmithingViewModel(player: player))
        _mainViewModel = StateObject(wrappedValue: mainViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: UIImage(named: "location\(GameStateService.shared.currentScene?.id.description ?? "Unknown")") ?? UIImage(named: "MainSceneBackground")!)
                    .resizable()
                    .ignoresSafeArea()
                
                DustEmitterView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        resourcesColumn()
                        Spacer()
                        craftingColumn()
                        Spacer()
                        recipesColumn()
                    }
                }
                .cornerRadius(12)
                .padding(25)
                
                VStack(alignment: .leading) {
                    TopWidgetView(viewModel: mainViewModel)
                        .frame(maxWidth: .infinity)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .foregroundColor(Theme.textColor)
                    
                    Spacer()
                }
            }
        }
    }
    
    func resourcesColumn() -> some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Resources")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                    
                    ForEach(viewModel.playerResources) { group in
                        ResourceRowView(group: group)
                            .padding(.horizontal, 6)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
        .frame(width: 200)
    }
    
    private func craftingColumn() -> some View {
        VStack {
            if let recipe = viewModel.selectedRecipe {
                if SmithingSystem.shared.checkCouldCraft(recipe: recipe, player: GameStateService.shared.player!) {
                    CraftingDetailView(
                        recipe: recipe,
                        isCrafting: viewModel.isCrafting,
                        onCraft: viewModel.craftItem
                    )
                }
            } else {
                Text("Select a recipe")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor.opacity(0.7))
            }
            
            if let result = viewModel.craftingResult {
                Text(result)
                    .font(Theme.bodyFont)
                    .foregroundColor(result.contains("Successfully") ? .green : .red)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            viewModel.clearResult()
                        }
                    }
            }
        }
    }
    
    private func recipesColumn() -> some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Recipes")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                    
                    let sortedRecipes = viewModel.availableRecipes.sorted { lhs, rhs in
                        let lhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == lhs.id })
                        let rhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == rhs.id })
                        if lhsCraftable == rhsCraftable {
                            return lhs.id < rhs.id // fallback order
                        }
                        return lhsCraftable && !rhsCraftable
                    }
                    ForEach(sortedRecipes) { recipe in
                        let isCraftable = viewModel.craftableRecipes.contains(where: { $0.id == recipe.id })
                        
                        Button(action: {
                            viewModel.selectRecipe(recipe)
                        }) {
                            RecipeRowView(
                                recipe: recipe,
                                isSelected: viewModel.selectedRecipe?.id == recipe.id,
                                isCraftable: isCraftable
                            )
                            .padding(.horizontal, 6)
                        }
                        .disabled(!isCraftable)
                        .opacity(isCraftable ? 1 : 0.5)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
        .frame(width: 200)
    }
} 
