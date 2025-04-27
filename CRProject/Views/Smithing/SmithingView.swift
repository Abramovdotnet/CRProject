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
            HStack {
                Text("Resources")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                
                Image(systemName: ItemType.resource.icon)
                    .font(Theme.bodyFont)
                    .foregroundColor(ItemType.resource.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 8)
            
            ZStack {
                ScrollView {
                    VStack(spacing: 8) {
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
            
            HStack {
                Text("Tools")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                
                Image(systemName: ItemType.tools.icon)
                    .font(Theme.bodyFont)
                    .foregroundColor(ItemType.tools.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 8)
            
            ZStack {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.playerTools) { group in
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
        }
        .padding(.top, 10)
        .frame(width: 250)
    }
    
    private func craftingColumn() -> some View {
        VStack {
            if let recipe = viewModel.selectedRecipe {
                CraftingDetailView(
                    recipe: recipe,
                    isCrafting: viewModel.isCrafting,
                    onCraft: viewModel.craftItem
                )
            } else {
                Text("Select a recipe")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor.opacity(0.7))
            }
            
            if let result = viewModel.craftingResult {
                Text(result)
                    .font(Theme.bodyFont)
                    .foregroundColor(.green)
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
            HStack {
                Text("Recipes")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                
                Image(systemName: ItemType.paper.icon)
                    .font(Theme.bodyFont)
                    .foregroundColor(ItemType.paper.color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 8)
            
            ZStack {
                ScrollView {
                    VStack(spacing: 8) {
                        
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
                            .opacity(isCraftable ? 1 : 0.9)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .mask(edgeMask)
                .frame(maxWidth: .infinity)

            }
        }
        .frame(width: 250)
        .padding(.top, 10)
    }
    
    private var edgeMask: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top fade
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
                
                // Middle section
                Rectangle()
                    .fill(Color.black)
                
                // Bottom fade
                LinearGradient(
                    gradient: Gradient(colors: [.black, .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
            }
        }
    }
}
