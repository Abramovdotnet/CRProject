import SwiftUI

// MARK: - Main View
struct SmithingView: View {
    @StateObject private var viewModel: SmithingViewModel
    @StateObject private var mainViewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Animation states
    @State private var backgroundOpacity = 0.0
    @State private var contentOpacity = 0.0
    @State private var moonPhase: Double = 0.0
    
    // ItemReader for accessing item details
    private let itemReader = ItemReader.shared
    
    init(player: Player, mainViewModel: MainSceneViewModel) {
        _viewModel = StateObject(wrappedValue: SmithingViewModel(player: player))
        _mainViewModel = StateObject(wrappedValue: mainViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView()
                
                // Content
                VStack(alignment: .leading) {
                    // Top bar
                    topBar(geometry: geometry)
                    
                    // Main content
                    mainContentView(geometry: geometry)
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    backgroundOpacity = 1
                }
                withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                    contentOpacity = 1
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                    moonPhase = 1
                }
            }
        }
    }
    
    private func backgroundView() -> some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            Image("anvil")
                .resizable()
                .opacity(0.8)
                .ignoresSafeArea()
            
            // Blood moon effect
            BloodMoonEffect(phase: moonPhase)
                .opacity(backgroundOpacity * 0.8)
                .ignoresSafeArea()
          
            // Blood mist effect
            EnhancedBloodMistEffect()
                .opacity(0.4)
                .ignoresSafeArea()
            
            DustEmitterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func topBar(geometry: GeometryProxy) -> some View {
        TopWidgetView(viewModel: mainViewModel)
            .frame(maxWidth: .infinity)
            .padding(.top, geometry.safeAreaInsets.top)
            .foregroundColor(Theme.textColor)
    }
    
    private func mainContentView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Left side - Recipes list
            recipesColumnView()
                .frame(maxWidth: geometry.size.width * 0.45)
            
            // Right side - Crafting details
            craftingColumnView()
                .frame(maxWidth: geometry.size.width * 0.55)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .opacity(contentOpacity)
    }
    
    private func craftingColumnView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed title without background
            Text("Crafting Details")
                .font(Theme.headingLightFont)
                .foregroundColor(Color.red)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider to separate title from content
            Divider()
                .background(Color.red.opacity(0.4))
            
            if let recipe = viewModel.selectedRecipe {
                if let result = viewModel.craftingResult {
                    VStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.8), radius: 8)
                            
                            Text(result)
                                .font(Theme.headingLightFont)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .shadow(color: .green.opacity(0.8), radius: 6)
                        }
                        .padding(24)
                        .shadow(color: .green.opacity(0.5), radius: 10)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            viewModel.clearResult()
                        }
                    }
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            recipeDetailView(recipe: recipe)
                        }
                        .padding(8)
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            } else {
                VStack(alignment: .center) {
                    Spacer()
                    Text("Select a Recipe")
                        .font(Theme.headingLightFont)
                        .foregroundColor(Theme.textColor.opacity(0.6))
                    
                    Image(systemName: "hammer.circle")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.textColor.opacity(0.3))
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
        .cornerRadius(12)
    }
    
    // Helper function to determine if a recipe is craftable
    private func isRecipeCraftable(_ recipe: Recipe) -> Bool {
        return viewModel.craftableRecipes.contains(where: { $0.id == recipe.id }) && !recipe.isUnknown
    }
    
    private func recipeDetailView(recipe: Recipe) -> some View {
        // Get the result item information
        let resultItem = itemReader.getItem(by: recipe.resultItemId)
        let isCraftable = isRecipeCraftable(recipe)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Recipe header split into components
            recipeHeaderView(recipe: recipe, resultItem: resultItem)
            
            // Recipe description - using item name instead of description
            if let item = resultItem {
                HStack {
                    Text("A crafting recipe for \(item.name)")
                        .font(Theme.smallFont.italic())
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 4)
                    Spacer()
                    Image(systemName: "hourglass.bottomhalf.fill")
                        .font(Theme.smallFont.italic())
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 4)
                    Text("Required time: \(AbilitiesSystem.shared.hasSmithingNovice ? Int(Double(recipe.productionTime) * 0.9) : AbilitiesSystem.shared.hasSmithingApprentice ? Int(Double(recipe.productionTime) * 0.8) : recipe.productionTime) hours")
                        .font(Theme.smallFont)
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 4)
                }
            }
            
            // Required materials
            VStack(alignment: .leading, spacing: 6) {
                Text("Required Materials:")
                    .font(Theme.bodyFont)
                    .foregroundColor(Color.white.opacity(0.9))
                    .padding(.bottom, 2)
                
                recipeRequirementsView(recipe: recipe, isCraftable: isCraftable)
            }
            .padding(.vertical, 4)
            
            // Craft button - only show if recipe is craftable and known
            if isRecipeCraftable(recipe) {
                Button(action: {
                    viewModel.craftItem()
                }) {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .font(Theme.bodyFont)
                        
                        Text("Craft Item")
                            .font(Theme.bodyFont)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(craftButtonBackground(recipe: recipe, resultItem: resultItem))
                    .cornerRadius(10)
                    .foregroundColor(craftButtonForegroundColor(recipe: recipe))
                    .shadow(color: craftButtonShadowColor(recipe: recipe, resultItem: resultItem), radius: 5, x: 0, y: 3)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
    }
    
    // Helper function for the recipe header
    private func recipeHeaderView(recipe: Recipe, resultItem: Item?) -> some View {
        HStack {
            if let item = resultItem {
                Image(systemName: item.icon())
                    .foregroundColor(item.color())
                    .frame(width: 30, height: 30)
                    .shadow(color: item.color().opacity(0.7), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(Theme.bodyFont)
                        .foregroundColor(Color.white)
                    
                    Text("Level \(recipe.professionLevel) \(item.type.rawValue)")
                        .font(Theme.bodyFont.weight(.light))
                        .foregroundColor(Color.white.opacity(0.7))
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 30, height: 30)
                
                Text("Unknown Item")
                    .font(Theme.bodyFont)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            Spacer()
            
            // Add value here and organize in a VStack
            VStack(alignment: .trailing, spacing: 2) {
                if !recipe.isUnknown {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .shadow(color: Color.green.opacity(0.5), radius: 6, x: 0, y: 3)
                }
                
                if let item = resultItem {
                    Text("Value: \(item.cost)")
                        .font(Theme.smallFont)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    // Helper function for resource row
    private func resourceRowView(resourceItem: Item?, count: Int, hasReq: Bool) -> some View {
        HStack(spacing: 2) {
            // Left part - resource name
            resourceNameView(resourceItem: resourceItem, hasReq: hasReq, requiredCount: count)
            
            // Right part - count
            if let resourceId = resourceItem?.id {
                let available = viewModel.getResourceCount(resourceId: resourceId)
                Text("×\(count)/\(available)")
                    .font(Theme.smallFont)
                    .foregroundColor(available >= count ? Color.green.opacity(0.95) : Color.red.opacity(0.95))
                    .lineLimit(1)
            } else {
                Text("×\(count)")
                    .font(Theme.smallFont)
                    .foregroundColor(hasReq ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.7))
        .cornerRadius(4)
        .frame(minWidth: 80)
    }
    
    // Helper function for resource name that doesn't define variables inside View builder
    private func resourceNameView(resourceItem: Item?, hasReq: Bool, requiredCount: Int = 1) -> some View {
        if let item = resourceItem {
            // Check if player has enough of this resource
            let resourceId = item.id
            let available = viewModel.getResourceCount(resourceId: resourceId)
            let hasEnough = available >= requiredCount
            
            // Use full name instead of abbreviation
            return Text(item.name)
                .font(Theme.smallFont)
                .foregroundColor(hasEnough ? Color.green.opacity(0.95) : Color.red.opacity(0.95))
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            return Text("?")
                .font(Theme.smallFont)
                .foregroundColor(Color.white.opacity(0.8))
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func recipesColumnView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title and Known toggle
            Text("Smithing Recipes")
                .font(Theme.headingLightFont)
                .foregroundColor(Color.red)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider to separate title from content
            Divider()
                .background(Color.red.opacity(0.4))
            
            // Filters section
            VStack(alignment: .leading, spacing: 8) {
                // Level filter
                HStack(spacing: 12) {
                    Text("Level:")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                    
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: {
                                viewModel.selectedProfessionLevel = viewModel.selectedProfessionLevel == level ? nil : level
                                viewModel.refreshRecipes()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.selectedProfessionLevel == level ? Recipe.professionlevelColor(level: level).opacity(0.3) : Color.black.opacity(0.3))
                                        .frame(width: 30, height: 30)
                                    
                                    Text("\(level)")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Recipe.professionlevelColor(level: level))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Type filter
                HStack(spacing: 12) {
                    Text("Filter:")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                    
                    // Rest of the HStack for the Type filter
                    HStack(spacing: 10) {
                        ForEach([ItemType.weapon, ItemType.armor], id: \.self) { type in
                            Button(action: {
                                viewModel.selectedItemType = viewModel.selectedItemType == type ? nil : type
                                viewModel.refreshRecipes()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(viewModel.selectedItemType == type ? Color.yellow.opacity(0.3) : Color.black.opacity(0.3))
                                        .frame(height: 30)
                                    
                                    HStack(spacing: 5) {
                                    Image(systemName: type.icon)
                                            .font(Theme.smallFont)
                                        
                                        Text(type.rawValue.capitalized)
                                            .font(Theme.smallFont)
                                    }
                                        .foregroundColor(viewModel.selectedItemType == type ? .yellow : Theme.textColor)
                                    .padding(.horizontal, 8)
                                }
                            }
                        }
                        
                        Button(action: {
                            viewModel.showOnlyKnownRecipes = !viewModel.showOnlyKnownRecipes
                            viewModel.refreshRecipes()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(viewModel.showOnlyKnownRecipes ? Color.yellow.opacity(0.3) : Color.black.opacity(0.3))
                                    .frame(height: 30)
                                
                                HStack(spacing: 5) {
                                    Image(systemName: "eye")
                                        .font(Theme.smallFont)
                                    
                                    Text("Known")
                                        .font(Theme.smallFont)
                                        .foregroundColor(viewModel.showOnlyKnownRecipes ? .yellow : Theme.textColor)
                                }
                                .foregroundColor(viewModel.showOnlyKnownRecipes ? .yellow : Theme.textColor)
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            
            // Scrollable recipe list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    // Simplified complex expression by breaking it into separate variables
                    let sortedByName = viewModel.availableRecipes.sorted(by: { $0.id < $1.id })
                    let sortedByLevel = sortedByName.sorted(by: { $0.professionLevel < $1.professionLevel })
                    let sortedByKnown = sortedByLevel.sorted(by: { !$0.isUnknown && $1.isUnknown })
                    
                    // Finally sort by craftable status
                    let sortedRecipes = sortedByKnown.sorted { lhs, rhs in
                        let lhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == lhs.id })
                        let rhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == rhs.id })
                        return lhsCraftable && !rhsCraftable
                    }
                    
                    ForEach(sortedRecipes) { recipe in
                        let isCraftable = isRecipeCraftable(recipe)
                        
                        recipeRowView(recipe: recipe, isCraftable: isCraftable)
                            .padding(.horizontal, 8)
                            .onTapGesture {
                                viewModel.selectRecipe(recipe)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .cornerRadius(12)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .cornerRadius(12)
    }
    
    private func recipeRowView(recipe: Recipe, isCraftable: Bool) -> some View {
        let isSelected = viewModel.selectedRecipe?.id == recipe.id
        let resultItem = itemReader.getItem(by: recipe.resultItemId)
        
        // Pre-compute colors to simplify the view modifiers
        let defaultColor = Color.black.opacity(0.6)
        let unavailableColor = Color.black.opacity(0.4)
        let itemColor = resultItem?.color() ?? Color.white.opacity(0.5)
        
        // Determine fill color
        let fillColor: Color
        if isSelected {
            fillColor = itemColor.opacity(0.3)
        } else if recipe.isUnknown || !isCraftable {
            fillColor = unavailableColor
        } else {
            fillColor = defaultColor
        }
        
        // Determine shadow color
        let shadowColor = isSelected ? itemColor.opacity(0.7) : Color.black.opacity(0.4)
        let shadowRadius: CGFloat = isSelected ? 6 : 2
        
        // Determine stroke color
        let strokeColor = isSelected ? itemColor.opacity(0.8) : Color.clear
        
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                // Recipe header
                recipeRowHeaderView(recipe: recipe, resultItem: resultItem)
                
                // Recipe requirements or Unknown text
                if !recipe.isUnknown {
                    VStack(alignment: .leading, spacing: 4) {
                        // First row of resources (up to 3)
                        HStack(spacing: 4) {
                            ForEach(recipe.requiredResources.prefix(min(3, recipe.requiredResources.count)), id: \.resourceId) { req in
                                createResourceRowView(for: req, isCraftable: isCraftable)
                            }
                        }
                        
                        // Additional resources if we have more than 3
                        if recipe.requiredResources.count > 3 {
                            HStack(spacing: 4) {
                                ForEach(recipe.requiredResources.suffix(recipe.requiredResources.count - 3), id: \.resourceId) { req in
                                    createResourceRowView(for: req, isCraftable: isCraftable)
                                }
                            }
                        }
                    }
                } else {
                    Text("Unknown Recipe")
                        .font(Theme.smallFont.italic())
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(fillColor)
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(strokeColor, lineWidth: 1)
        )
        .opacity(recipe.isUnknown ? 0.85 : 1.0)
    }
    
    // Helper for recipe row header
    private func recipeRowHeaderView(recipe: Recipe, resultItem: Item?) -> some View {
        HStack {
            if let item = resultItem {
                Image(systemName: item.icon())
                    .foregroundColor(item.color())
                    .frame(width: 20, height: 20)
                    .shadow(color: item.color().opacity(0.5), radius: 3, x: 0, y: 2)
                
                Text(recipe.isUnknown ? "Unknown Recipe" : item.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(recipe.isUnknown ? Color.white.opacity(0.7) : Color.white)
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20, height: 20)
                
                Text("Unknown Recipe")
                    .font(Theme.bodyFont)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Level indicator
            ZStack {
                Circle()
                    .fill(Recipe.professionlevelColor(level: recipe.professionLevel).opacity(0.3))
                    .frame(width: 24, height: 24)
                
                Text("\(recipe.professionLevel)")
                    .font(Theme.smallFont)
                    .foregroundColor(Recipe.professionlevelColor(level: recipe.professionLevel))
            }
        }
    }
    
    // Helper for recipe requirements (ingredients list)
    private func recipeRequirementsView(recipe: Recipe, isCraftable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // First row of resources
            HStack(spacing: 4) {
                ForEach(recipe.requiredResources.prefix(3), id: \.resourceId) { req in
                    createResourceRowView(for: req, isCraftable: isCraftable)
                }
            }
            
            // Show additional resources on a second row if needed
            if recipe.requiredResources.count > 3 {
                HStack(spacing: 4) {
                    ForEach(recipe.requiredResources.suffix(from: 3), id: \.resourceId) { req in
                        createResourceRowView(for: req, isCraftable: isCraftable)
                    }
                }
            }
        }
    }
    
    // Helper function to create a resource view for a requirement
    private func createResourceRowView(for requirement: RecipeResource, isCraftable: Bool) -> some View {
        let resourceItem = itemReader.getItem(by: requirement.resourceId)
        return resourceRowView(resourceItem: resourceItem, count: requirement.count, hasReq: isCraftable)
    }
    
    private func craftButtonBackground(recipe: Recipe, resultItem: Item?) -> AnyView {
        let isCraftable = isRecipeCraftable(recipe)
        
        if isCraftable {
            let color1 = (resultItem?.color() ?? .gray).opacity(0.4)
            let color2 = (resultItem?.color() ?? .gray).opacity(0.6)
            return AnyView(
                LinearGradient(
                    gradient: Gradient(colors: [color1, color2]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            return AnyView(Color.white.opacity(0.1))
        }
    }
    
    private func craftButtonForegroundColor(recipe: Recipe) -> Color {
        let isCraftable = isRecipeCraftable(recipe)
        return isCraftable ? Color.white : Color.white.opacity(0.5)
    }
    
    private func craftButtonShadowColor(recipe: Recipe, resultItem: Item?) -> Color {
        let isCraftable = isRecipeCraftable(recipe)
        return isCraftable ? (resultItem?.color() ?? .gray).opacity(0.5) : Color.white.opacity(0.1)
    }
}
