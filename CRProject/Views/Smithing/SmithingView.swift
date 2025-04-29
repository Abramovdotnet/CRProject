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
                        recipesColumn()
                        Spacer()
                        craftingColumn()
                    }
                }
                .cornerRadius(12)
                .padding(.top, 10)
                
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
    
    private func craftingColumn() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let recipe = viewModel.selectedRecipe {
                    if let result = viewModel.craftingResult {
                        Text(result)
                            .font(Theme.bodyFont)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.black.opacity(0.9))
                            .cornerRadius(8)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    viewModel.clearResult()
                                }
                            }
                    } else {
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
                Spacer()
            }
            Spacer()
        }
    }
    
    private func recipesColumn() -> some View {
        ZStack {
            VStack {
                VStack {
                    // First filter: Profession Level
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: {
                                viewModel.selectedProfessionLevel = viewModel.selectedProfessionLevel == level ? nil : level
                                viewModel.refreshRecipes()
                            }) {
                                ZStack{
                                    Circle()
                                        .fill(viewModel.selectedProfessionLevel == level ? Recipe.professionlevelColor(level: level).opacity(0.3) : Color.clear)
                                        .blur(radius: 5)
                                        .opacity(0.9)
                                    
                                    Image(systemName: "hammer.fill")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Recipe.professionlevelColor(level: level))
                                        .shadow(color: Recipe.professionlevelColor(level: level).opacity(0.8), radius: 5, x: 1, y: 1)
                                }
                                .frame(width: 30, height: 30)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 5)
                    
                    // Second filter: Item Type and Known Recipes
                    HStack(spacing: 8) {
                        ForEach([ItemType.weapon, ItemType.armor], id: \.self) { type in
                            Button(action: {
                                viewModel.selectedItemType = viewModel.selectedItemType == type ? nil : type
                                viewModel.refreshRecipes()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.selectedItemType == type ? Color.yellow.opacity(0.3) : Color.clear)
                                        .blur(radius: 5)
                                        .opacity(0.9)
                                    
                                    Image(systemName: type.icon)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(viewModel.selectedItemType == type ? .yellow : Theme.textColor)
                                }
                                .frame(width: 30, height: 30)
                            }
                        }
                        // Known recipes filter button
                        Button(action: {
                            viewModel.showOnlyKnownRecipes.toggle()
                            viewModel.refreshRecipes()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.showOnlyKnownRecipes ? "eye.slash" : "eye")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(viewModel.showOnlyKnownRecipes ? .yellow : Theme.textColor)
                                Text("Known")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(viewModel.showOnlyKnownRecipes ? .yellow : Theme.textColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(.top, 5)
                .frame(maxWidth: .infinity)
                
                ZStack {
                    ScrollView {
                        VStack(spacing: 4) {
                            
                            let sortedRecipes = viewModel.availableRecipes.sorted { lhs, rhs in
                                let lhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == lhs.id })
                                let rhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == rhs.id })
                                if lhsCraftable == rhsCraftable {
                                    return lhs.id < rhs.id // fallback order
                                }
                                return lhsCraftable && !rhsCraftable
                            }
                            ForEach(sortedRecipes) { recipe in
                                let isCraftable = viewModel.craftableRecipes.contains(where: { $0.id == recipe.id && !recipe.isUnknown})
                                
                                Button(action: {
                                    viewModel.selectRecipe(recipe)
                                }) {
                                    RecipeRowViewShort(
                                        recipe: recipe,
                                        isSelected: viewModel.selectedRecipe?.id == recipe.id,
                                        isCraftable: isCraftable
                                    )
                                    .padding(.horizontal, 6)
                                }
                                .opacity(isCraftable ? 1 : 0.7)
                                .padding(.top, 10)
                                .padding(.bottom, -10)
                            }
                        }
                    }
                    .mask(edgeMask)
                    .frame(maxWidth: .infinity)

                }
            }
        }
        .cornerRadius(12)
        .frame(width: 300)
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
