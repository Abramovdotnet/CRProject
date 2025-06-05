import UIKit
import SwiftUI
import Combine

class SmithingViewController: UIViewController {
    private let player: Player
    private let mainViewModel: MainSceneViewModel
    
    // Background components
    private let backgroundImageView = UIImageView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    
    // Top widget
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    // Main containers
    private let recipesContainerView = UIView()
    private let craftingContainerView = UIView()
    
    // Recipe list components
    private let recipesScrollView = UIScrollView()
    private let recipesStackView = UIStackView()
    private let filtersContainerView = UIView()
    
    // Crafting details components
    private let craftingStackView = UIStackView()
    
    // Filter buttons
    private var levelFilterButtons: [UIButton] = []
    private var typeFilterButtons: [ActionButtonSmallView] = []
    private var knownFilterButton: ActionButtonSmallView!
    
    // Data
    private var viewModel: SmithingViewModel!
    
    // State
    private var selectedRecipe: Recipe?
    private var cancellables = Set<AnyCancellable>()
    
    init(player: Player, mainViewModel: MainSceneViewModel) {
        self.player = player
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel = SmithingViewModel(player: player)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.clipsToBounds = false
        
        setupBackground()
        setupTopWidget()
        setupMainContainers()
        setupFilters()
        setupRecipesList()
        setupCraftingDetails()
        setupLayout()
        setupObservers()
        
        // Load initial data
        updateRecipesList()
        showSelectRecipeMessage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Background и dust effect теперь управляются constraints - никаких костылей не нужно
    }
    
    // MARK: - Setup Methods
    
    private func setupBackground() {
        // Background image
        backgroundImageView.image = UIImage(named: "anvil")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        backgroundImageView.alpha = 0.8
        view.addSubview(backgroundImageView)
        
        // Dust effect
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        addChild(dustViewHostingController)
        view.addSubview(dustViewHostingController.view)
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
    }
    
    private func setupTopWidget() {
        topWidgetContainerView.backgroundColor = .clear
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topWidgetContainerView)
        
        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC
    }
    
    private func setupMainContainers() {
        // Recipes container (left side)
        recipesContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        recipesContainerView.layer.cornerRadius = 12
        view.addSubview(recipesContainerView)
        
        // Crafting container (right side)
        craftingContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        craftingContainerView.layer.cornerRadius = 12
        view.addSubview(craftingContainerView)
    }
    
    private func setupFilters() {
        filtersContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        filtersContainerView.layer.cornerRadius = 12
        filtersContainerView.translatesAutoresizingMaskIntoConstraints = false
        recipesContainerView.addSubview(filtersContainerView)
        
        // Level filter buttons (1-5)
        let levelStackView = UIStackView()
        levelStackView.axis = .horizontal
        levelStackView.spacing = 10
        levelStackView.translatesAutoresizingMaskIntoConstraints = false
        filtersContainerView.addSubview(levelStackView)
        
        for level in 1...5 {
            let button = createLevelFilterButton(level: level)
            levelFilterButtons.append(button)
            levelStackView.addArrangedSubview(button)
        }
        
        // Type filter buttons
        let typeStackView = UIStackView()
        typeStackView.axis = .horizontal
        typeStackView.spacing = 8
        typeStackView.distribution = .fillEqually
        typeStackView.translatesAutoresizingMaskIntoConstraints = false
        filtersContainerView.addSubview(typeStackView)
        
        let weaponButton = createTypeFilterButton(type: .weapon)
        let armorButton = createTypeFilterButton(type: .armor)
        knownFilterButton = createKnownFilterButton()
        
        typeFilterButtons = [weaponButton, armorButton]
        typeStackView.addArrangedSubview(weaponButton)
        typeStackView.addArrangedSubview(armorButton)
        typeStackView.addArrangedSubview(knownFilterButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            levelStackView.topAnchor.constraint(equalTo: filtersContainerView.topAnchor, constant: 16),
            levelStackView.centerXAnchor.constraint(equalTo: filtersContainerView.centerXAnchor),
            
            typeStackView.topAnchor.constraint(equalTo: levelStackView.bottomAnchor, constant: 20),
            typeStackView.leadingAnchor.constraint(equalTo: filtersContainerView.leadingAnchor, constant: 16),
            typeStackView.trailingAnchor.constraint(lessThanOrEqualTo: filtersContainerView.trailingAnchor, constant: -16),
            typeStackView.bottomAnchor.constraint(equalTo: filtersContainerView.bottomAnchor, constant: -16),
            
            // Add explicit height constraint to prevent conflicts
            filtersContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }
    
    private func setupRecipesList() {
        recipesScrollView.showsVerticalScrollIndicator = false
        recipesScrollView.translatesAutoresizingMaskIntoConstraints = false
        recipesContainerView.addSubview(recipesScrollView)
        
        recipesStackView.axis = .vertical
        recipesStackView.spacing = 8
        recipesStackView.translatesAutoresizingMaskIntoConstraints = false
        recipesScrollView.addSubview(recipesStackView)
    }
    
    private func setupCraftingDetails() {
        craftingStackView.axis = .vertical
        craftingStackView.spacing = 8
        craftingStackView.alignment = .fill
        craftingStackView.distribution = .fillProportionally
        craftingStackView.translatesAutoresizingMaskIntoConstraints = false
        craftingContainerView.addSubview(craftingStackView)
    }
    
    private func setupLayout() {
        recipesContainerView.translatesAutoresizingMaskIntoConstraints = false
        craftingContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Top widget
            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),
            
            // Top widget content
            topWidgetViewController!.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor),
            topWidgetViewController!.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor),
            topWidgetViewController!.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor),
            topWidgetViewController!.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor),
            
            // Recipes container (left side)
            recipesContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 10),
            recipesContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recipesContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            recipesContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Crafting container (right side)
            craftingContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 10),
            craftingContainerView.leadingAnchor.constraint(equalTo: recipesContainerView.trailingAnchor, constant: 20),
            craftingContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Filters container
            filtersContainerView.topAnchor.constraint(equalTo: recipesContainerView.topAnchor, constant: 60),
            filtersContainerView.leadingAnchor.constraint(equalTo: recipesContainerView.leadingAnchor, constant: 8),
            filtersContainerView.trailingAnchor.constraint(equalTo: recipesContainerView.trailingAnchor, constant: -8),
            
            // Recipes scroll view
            recipesScrollView.topAnchor.constraint(equalTo: filtersContainerView.bottomAnchor, constant: 8),
            recipesScrollView.leadingAnchor.constraint(equalTo: recipesContainerView.leadingAnchor, constant: 8),
            recipesScrollView.trailingAnchor.constraint(equalTo: recipesContainerView.trailingAnchor, constant: -8),
            recipesScrollView.bottomAnchor.constraint(equalTo: recipesContainerView.bottomAnchor, constant: -8),
            
            // Recipes stack view
            recipesStackView.topAnchor.constraint(equalTo: recipesScrollView.topAnchor, constant: 8),
            recipesStackView.leadingAnchor.constraint(equalTo: recipesScrollView.leadingAnchor, constant: 8),
            recipesStackView.trailingAnchor.constraint(equalTo: recipesScrollView.trailingAnchor, constant: -8),
            recipesStackView.bottomAnchor.constraint(equalTo: recipesScrollView.bottomAnchor, constant: -8),
            recipesStackView.widthAnchor.constraint(equalTo: recipesScrollView.widthAnchor, constant: -16),
            
            // Crafting stack view
            craftingStackView.topAnchor.constraint(equalTo: craftingContainerView.topAnchor, constant: 40),
            craftingStackView.leadingAnchor.constraint(equalTo: craftingContainerView.leadingAnchor, constant: 12),
            craftingStackView.trailingAnchor.constraint(equalTo: craftingContainerView.trailingAnchor, constant: -12),
            craftingStackView.bottomAnchor.constraint(equalTo: craftingContainerView.bottomAnchor, constant: -12)
        ])
        
        // Add low priority constraint to allow crafting container to shrink
        let maxHeightConstraint = craftingContainerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        maxHeightConstraint.priority = UILayoutPriority(999)
        maxHeightConstraint.isActive = true
        
        // Add titles
        addContainerTitles()
    }
    
    private func setupObservers() {
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateRecipesList()
                self?.updateCraftingDetails()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UI Creation Helpers

extension SmithingViewController {
    private func createLevelFilterButton(level: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(level)", for: .normal)
        button.titleLabel?.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 15
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.tag = level
        button.addTarget(self, action: #selector(levelFilterTapped(_:)), for: .touchUpInside)
        
        // Set initial color based on level
        let levelColor = getLevelColor(level: level)
        button.setTitleColor(levelColor, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = levelColor.withAlphaComponent(0.3).cgColor
        
        return button
    }
    
    private func createTypeFilterButton(type: ItemType) -> ActionButtonSmallView {
        let button = ActionButtonSmallView(filterType: type)
        button.addTarget(self, action: #selector(typeFilterTapped(_:)), for: .touchUpInside)
        
        // Store type in button
        button.accessibilityIdentifier = type.rawValue
        
        return button
    }
    
    private func createKnownFilterButton() -> ActionButtonSmallView {
        let button = ActionButtonSmallView(knownFilter: true)
        button.addTarget(self, action: #selector(knownFilterTapped), for: .touchUpInside)
        
        return button
    }
    
    private func addContainerTitles() {
        // Recipes title
        let recipesTitle = UILabel()
        recipesTitle.text = "Smithing Recipes"
        recipesTitle.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        recipesTitle.textColor = .systemRed
        recipesTitle.textAlignment = .center
        recipesTitle.translatesAutoresizingMaskIntoConstraints = false
        recipesContainerView.addSubview(recipesTitle)
        
        // Crafting title
        let craftingTitle = UILabel()
        craftingTitle.text = "Crafting Details"
        craftingTitle.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        craftingTitle.textColor = .systemRed
        craftingTitle.textAlignment = .center
        craftingTitle.translatesAutoresizingMaskIntoConstraints = false
        craftingContainerView.addSubview(craftingTitle)
        
        NSLayoutConstraint.activate([
            recipesTitle.topAnchor.constraint(equalTo: recipesContainerView.topAnchor, constant: 16),
            recipesTitle.leadingAnchor.constraint(equalTo: recipesContainerView.leadingAnchor, constant: 16),
            recipesTitle.trailingAnchor.constraint(equalTo: recipesContainerView.trailingAnchor, constant: -16),
            
            craftingTitle.topAnchor.constraint(equalTo: craftingContainerView.topAnchor, constant: 16),
            craftingTitle.leadingAnchor.constraint(equalTo: craftingContainerView.leadingAnchor, constant: 16),
            craftingTitle.trailingAnchor.constraint(equalTo: craftingContainerView.trailingAnchor, constant: -16)
        ])
    }
}

// MARK: - Action Handlers

extension SmithingViewController {
    @objc private func levelFilterTapped(_ sender: UIButton) {
        let level = sender.tag
        
        // Toggle level filter
        if viewModel.selectedProfessionLevel == level {
            viewModel.selectedProfessionLevel = nil
        } else {
            viewModel.selectedProfessionLevel = level
        }
        
        updateLevelFilterButtons()
        viewModel.refreshRecipes()
    }
    
    @objc private func typeFilterTapped(_ sender: ActionButtonSmallView) {
        guard let typeString = sender.accessibilityIdentifier,
              let type = ItemType(rawValue: typeString) else { return }
        
        // Toggle type filter
        if viewModel.selectedItemType == type {
            viewModel.selectedItemType = nil
        } else {
            viewModel.selectedItemType = type
        }
        
        updateTypeFilterButtons()
        viewModel.refreshRecipes()
    }
    
    @objc private func knownFilterTapped() {
        viewModel.showOnlyKnownRecipes = !viewModel.showOnlyKnownRecipes
        updateKnownFilterButton()
        viewModel.refreshRecipes()
    }
    
    @objc private func recipeCardTapped(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view,
              let recipe = getRecipeFromView(cardView) else { return }
        
        selectedRecipe = recipe
        viewModel.selectRecipe(recipe)
        updateRecipesList()
        updateCraftingDetails()
    }
    
    @objc private func craftButtonTapped() {
        viewModel.craftItem()
        // Show crafting result will be handled by observer
    }
}

// MARK: - Update Methods

extension SmithingViewController {
    private func updateRecipesList() {
        // Clear existing recipe cards
        recipesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Sort recipes like in SwiftUI version
        let sortedByName = viewModel.availableRecipes.sorted(by: { $0.id < $1.id })
        let sortedByLevel = sortedByName.sorted(by: { $0.professionLevel < $1.professionLevel })
        let sortedByKnown = sortedByLevel.sorted(by: { !$0.isUnknown && $1.isUnknown })
        let sortedRecipes = sortedByKnown.sorted { lhs, rhs in
            let lhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == lhs.id })
            let rhsCraftable = viewModel.craftableRecipes.contains(where: { $0.id == rhs.id })
            return lhsCraftable && !rhsCraftable
        }
        
        // Create recipe cards
        for recipe in sortedRecipes {
            let isCraftable = isRecipeCraftable(recipe)
            let recipeCard = createRecipeCard(recipe: recipe, isCraftable: isCraftable)
            recipesStackView.addArrangedSubview(recipeCard)
        }
    }
    
    private func updateCraftingDetails() {
        // Clear existing content
        craftingStackView.arrangedSubviews.forEach { 
            craftingStackView.removeArrangedSubview($0)
            $0.removeFromSuperview() 
        }
        
        if let craftingResult = viewModel.craftingResult {
            showCraftingResult(craftingResult)
        } else if let recipe = selectedRecipe {
            showRecipeDetails(recipe)
        } else {
            showSelectRecipeMessage()
        }
    }
    
    private func updateLevelFilterButtons() {
        for button in levelFilterButtons {
            let level = button.tag
            let isSelected = viewModel.selectedProfessionLevel == level
            let levelColor = getLevelColor(level: level)
            
            if isSelected {
                button.backgroundColor = levelColor.withAlphaComponent(0.3)
                button.layer.borderColor = levelColor.cgColor
            } else {
                button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                button.layer.borderColor = levelColor.withAlphaComponent(0.3).cgColor
            }
        }
    }
    
    private func updateTypeFilterButtons() {
        for button in typeFilterButtons {
            guard let typeString = button.accessibilityIdentifier,
                  let type = ItemType(rawValue: typeString) else { continue }
            
            let isSelected = viewModel.selectedItemType == type
            
            if isSelected {
                button.alpha = 1.0
                button.layer.shadowOpacity = 0.8
            } else {
                button.alpha = 0.7
                button.layer.shadowOpacity = 0.3
            }
        }
    }
    
    private func updateKnownFilterButton() {
        let isSelected = viewModel.showOnlyKnownRecipes
        
        if isSelected {
            knownFilterButton.layer.shadowOpacity = 0.8
        } else {
            knownFilterButton.layer.shadowOpacity = 0.3
        }
    }
}

// MARK: - Recipe Card Creation

extension SmithingViewController {
    private func createRecipeCard(recipe: Recipe, isCraftable: Bool) -> UIView {
        let itemReader = ItemReader.shared
        let resultItem = itemReader.getItem(by: recipe.resultItemId)
        let isSelected = selectedRecipe?.id == recipe.id
        
        let containerView = UIView()
        containerView.backgroundColor = getRecipeCardBackgroundColor(recipe: recipe, isCraftable: isCraftable, isSelected: isSelected)
        containerView.layer.cornerRadius = 8
        
        // Shadow and border
        let itemColor = ActionButtonSmallView.convertSwiftUIColorToUIColor(resultItem?.color() ?? Color.white)
        if isSelected {
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = itemColor.cgColor
            containerView.layer.shadowColor = itemColor.cgColor
            containerView.layer.shadowRadius = 6
            containerView.layer.shadowOpacity = 0.7
            containerView.layer.shadowOffset = .zero
        } else {
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowRadius = 2
            containerView.layer.shadowOpacity = 0.4
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
        
        // Main stack view
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 8
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mainStackView)
        
        // Header with icon, name, and level
        let headerView = createRecipeCardHeader(recipe: recipe, resultItem: resultItem)
        mainStackView.addArrangedSubview(headerView)
        
        // Requirements or Unknown text
        if !recipe.isUnknown {
            let requirementsView = createRecipeCardRequirements(recipe: recipe, isCraftable: isCraftable)
            mainStackView.addArrangedSubview(requirementsView)
        } else {
            let unknownLabel = UILabel()
            unknownLabel.text = "Unknown Recipe"
            unknownLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .light)
            unknownLabel.textColor = UIColor.white.withAlphaComponent(0.7)
            unknownLabel.textAlignment = .center
            mainStackView.addArrangedSubview(unknownLabel)
        }
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recipeCardTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        // Store recipe reference
        containerView.accessibilityIdentifier = "\(recipe.id)"
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
        
        return containerView
    }
    
    private func createRecipeCardHeader(recipe: Recipe, resultItem: Item?) -> UIView {
        let headerView = UIView()
        
        let iconImageView = UIImageView()
        if let item = resultItem {
            iconImageView.image = UIImage(systemName: item.icon())
            iconImageView.tintColor = ActionButtonSmallView.convertSwiftUIColorToUIColor(item.color())
        } else {
            iconImageView.image = UIImage(systemName: "questionmark.circle")
            iconImageView.tintColor = UIColor.white.withAlphaComponent(0.7)
        }
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = recipe.isUnknown ? "Unknown Recipe" : (resultItem?.name ?? "Unknown Item")
        nameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = recipe.isUnknown ? UIColor.white.withAlphaComponent(0.7) : .white
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let levelView = UIView()
        levelView.backgroundColor = getLevelColor(level: recipe.professionLevel).withAlphaComponent(0.3)
        levelView.layer.cornerRadius = 12
        levelView.translatesAutoresizingMaskIntoConstraints = false
        
        let levelLabel = UILabel()
        levelLabel.text = "\(recipe.professionLevel)"
        levelLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        levelLabel.textColor = getLevelColor(level: recipe.professionLevel)
        levelLabel.textAlignment = .center
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelView.addSubview(levelLabel)
        
        headerView.addSubview(iconImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(levelView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: levelView.leadingAnchor, constant: -8),
            
            levelView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            levelView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            levelView.widthAnchor.constraint(equalToConstant: 24),
            levelView.heightAnchor.constraint(equalToConstant: 24),
            
            levelLabel.centerXAnchor.constraint(equalTo: levelView.centerXAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: levelView.centerYAnchor),
            
            headerView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return headerView
    }
    
    private func createRecipeCardRequirements(recipe: Recipe, isCraftable: Bool) -> UIView {
        let requirementsView = UIView()
        
        // First row
        let firstRowStackView = UIStackView()
        firstRowStackView.axis = .horizontal
        firstRowStackView.spacing = 4
        firstRowStackView.translatesAutoresizingMaskIntoConstraints = false
        requirementsView.addSubview(firstRowStackView)
        
        // Add first 3 requirements
        for req in recipe.requiredResources.prefix(3) {
            let resourceView = createResourceView(for: req, isCraftable: isCraftable)
            firstRowStackView.addArrangedSubview(resourceView)
        }
        
        var constraints = [
            firstRowStackView.topAnchor.constraint(equalTo: requirementsView.topAnchor),
            firstRowStackView.leadingAnchor.constraint(equalTo: requirementsView.leadingAnchor),
            firstRowStackView.trailingAnchor.constraint(equalTo: requirementsView.trailingAnchor)
        ]
        
        // Second row if needed
        if recipe.requiredResources.count > 3 {
            let secondRowStackView = UIStackView()
            secondRowStackView.axis = .horizontal
            secondRowStackView.spacing = 4
            secondRowStackView.translatesAutoresizingMaskIntoConstraints = false
            requirementsView.addSubview(secondRowStackView)
            
            for req in recipe.requiredResources.suffix(from: 3) {
                let resourceView = createResourceView(for: req, isCraftable: isCraftable)
                secondRowStackView.addArrangedSubview(resourceView)
            }
            
            constraints.append(contentsOf: [
                secondRowStackView.topAnchor.constraint(equalTo: firstRowStackView.bottomAnchor, constant: 4),
                secondRowStackView.leadingAnchor.constraint(equalTo: requirementsView.leadingAnchor),
                secondRowStackView.trailingAnchor.constraint(equalTo: requirementsView.trailingAnchor),
                secondRowStackView.bottomAnchor.constraint(equalTo: requirementsView.bottomAnchor)
            ])
        } else {
            constraints.append(firstRowStackView.bottomAnchor.constraint(equalTo: requirementsView.bottomAnchor))
        }
        
        NSLayoutConstraint.activate(constraints)
        
        return requirementsView
    }
    
    private func createResourceView(for requirement: RecipeResource, isCraftable: Bool) -> UIView {
        let itemReader = ItemReader.shared
        let resourceItem = itemReader.getItem(by: requirement.resourceId)
        let available = viewModel.getResourceCount(resourceId: requirement.resourceId)
        let hasEnough = available >= requirement.count
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 4
        
        let label = UILabel()
        if let item = resourceItem {
            label.text = "\(item.name): \(requirement.count)/\(available)"
        } else {
            label.text = "?: \(requirement.count)"
        }
        label.font = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
        label.textColor = hasEnough ? UIColor.green.withAlphaComponent(0.95) : UIColor.red.withAlphaComponent(0.95)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -2),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        return containerView
    }
}

// MARK: - Crafting Details Creation

extension SmithingViewController {
    private func showSelectRecipeMessage() {
        clearCraftingContent()
        
        let messageLabel = UILabel()
        messageLabel.text = "Select a recipe to view crafting details"
        messageLabel.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .light)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        messageLabel.textAlignment = .left
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "hammer.circle")
        iconImageView.tintColor = UIColor.white.withAlphaComponent(0.3)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create container with left alignment
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        containerView.addSubview(messageLabel)
        
        craftingStackView.addArrangedSubview(containerView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
    }
    
    private func showCraftingResult(_ result: String) {
        clearCraftingContent()
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
        iconImageView.tintColor = .systemGreen
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add glow effect
        iconImageView.layer.shadowColor = UIColor.systemGreen.cgColor
        iconImageView.layer.shadowRadius = 8
        iconImageView.layer.shadowOpacity = 0.8
        iconImageView.layer.shadowOffset = .zero
        
        let resultLabel = UILabel()
        resultLabel.text = result
        resultLabel.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .light)
        resultLabel.textColor = .systemGreen
        resultLabel.textAlignment = .left
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add glow effect to text
        resultLabel.layer.shadowColor = UIColor.systemGreen.cgColor
        resultLabel.layer.shadowRadius = 6
        resultLabel.layer.shadowOpacity = 0.8
        resultLabel.layer.shadowOffset = .zero
        
        // Create container with horizontal layout
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        containerView.addSubview(resultLabel)
        
        craftingStackView.addArrangedSubview(containerView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            resultLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            resultLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
        
        // Auto-clear result after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.viewModel.clearResult()
        }
    }
    
    private func showRecipeDetails(_ recipe: Recipe) {
        clearCraftingContent()
        
        let itemReader = ItemReader.shared
        let resultItem = itemReader.getItem(by: recipe.resultItemId)
        let isCraftable = isRecipeCraftable(recipe)
        
        // Recipe header
        let headerView = createRecipeDetailHeader(recipe: recipe, resultItem: resultItem)
        craftingStackView.addArrangedSubview(headerView)
        
        // Production time
        let timeLabel = UILabel()
        let abilitiesSystem = AbilitiesSystem.shared
        let baseTime = recipe.productionTime
        let modifiedTime: Int
        if abilitiesSystem.hasSmithingNovice {
            modifiedTime = Int(Double(baseTime) * 0.9)
        } else if abilitiesSystem.hasSmithingApprentice {
            modifiedTime = Int(Double(baseTime) * 0.8)
        } else {
            modifiedTime = baseTime
        }
        
        timeLabel.text = "⏳ Required time: \(modifiedTime) hours"
        timeLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        craftingStackView.addArrangedSubview(timeLabel)
        
        // Required materials
        let materialsLabel = UILabel()
        materialsLabel.text = "Required Materials:"
        materialsLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        materialsLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        craftingStackView.addArrangedSubview(materialsLabel)
        
        let requirementsView = createDetailedRequirements(recipe: recipe, isCraftable: isCraftable)
        craftingStackView.addArrangedSubview(requirementsView)
        
        // Craft button (only if craftable)
        if isCraftable {
            let craftButton = createCraftButton(recipe: recipe, resultItem: resultItem)
            
            // Create container for button alignment
            let buttonContainer = UIView()
            buttonContainer.translatesAutoresizingMaskIntoConstraints = false
            buttonContainer.addSubview(craftButton)
            
            craftingStackView.addArrangedSubview(buttonContainer)
            
            // Add constraints for button positioning
            NSLayoutConstraint.activate([
                craftButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
                craftButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
                craftButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
                craftButton.heightAnchor.constraint(equalToConstant: 36),
                craftButton.widthAnchor.constraint(lessThanOrEqualTo: buttonContainer.widthAnchor)
            ])
        }
    }
    
    private func createRecipeDetailHeader(recipe: Recipe, resultItem: Item?) -> UIView {
        let headerView = UIView()
        
        let iconImageView = UIImageView()
        if let item = resultItem {
            iconImageView.image = UIImage(systemName: item.icon())
            iconImageView.tintColor = ActionButtonSmallView.convertSwiftUIColorToUIColor(item.color())
            
            // Add glow effect
            let itemColor = ActionButtonSmallView.convertSwiftUIColorToUIColor(item.color())
            iconImageView.layer.shadowColor = itemColor.cgColor
            iconImageView.layer.shadowRadius = 8
            iconImageView.layer.shadowOpacity = 0.7
            iconImageView.layer.shadowOffset = .zero
        } else {
            iconImageView.image = UIImage(systemName: "questionmark.circle")
            iconImageView.tintColor = UIColor.white.withAlphaComponent(0.7)
        }
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = resultItem?.name ?? "Unknown Item"
        nameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let levelLabel = UILabel()
        levelLabel.text = "Level \(recipe.professionLevel) \(resultItem?.type.rawValue ?? "Unknown")"
        levelLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .light)
        levelLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        if let item = resultItem {
            valueLabel.text = "Value: \(item.cost)"
            valueLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
            valueLabel.textColor = .systemGreen
            valueLabel.textAlignment = .right
        }
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(iconImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(levelLabel)
        headerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8),
            
            levelLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            levelLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    private func createDetailedRequirements(recipe: Recipe, isCraftable: Bool) -> UIView {
        let requirementsView = UIView()
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        requirementsView.addSubview(stackView)
        
        // First row
        let firstRowStackView = UIStackView()
        firstRowStackView.axis = .horizontal
        firstRowStackView.spacing = 6
        firstRowStackView.distribution = .fillEqually
        
        for req in recipe.requiredResources.prefix(3) {
            let resourceView = createDetailedResourceView(for: req, isCraftable: isCraftable)
            firstRowStackView.addArrangedSubview(resourceView)
        }
        
        stackView.addArrangedSubview(firstRowStackView)
        
        // Second row if needed
        if recipe.requiredResources.count > 3 {
            let secondRowStackView = UIStackView()
            secondRowStackView.axis = .horizontal
            secondRowStackView.spacing = 6
            secondRowStackView.distribution = .fillEqually
            
            for req in recipe.requiredResources.suffix(from: 3) {
                let resourceView = createDetailedResourceView(for: req, isCraftable: isCraftable)
                secondRowStackView.addArrangedSubview(resourceView)
            }
            
            stackView.addArrangedSubview(secondRowStackView)
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: requirementsView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: requirementsView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: requirementsView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: requirementsView.bottomAnchor)
        ])
        
        return requirementsView
    }
    
    private func createDetailedResourceView(for requirement: RecipeResource, isCraftable: Bool) -> UIView {
        let itemReader = ItemReader.shared
        let resourceItem = itemReader.getItem(by: requirement.resourceId)
        let available = viewModel.getResourceCount(resourceId: requirement.resourceId)
        let hasEnough = available >= requirement.count
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 6
        
        let resourceLabel = UILabel()
        if let item = resourceItem {
            resourceLabel.text = "\(item.name): \(requirement.count)/\(available)"
        } else {
            resourceLabel.text = "Unknown: \(requirement.count)"
        }
        resourceLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        resourceLabel.textColor = hasEnough ? UIColor.green.withAlphaComponent(0.95) : UIColor.red.withAlphaComponent(0.95)
        resourceLabel.textAlignment = .center
        resourceLabel.numberOfLines = 1
        resourceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(resourceLabel)
        
        NSLayoutConstraint.activate([
            resourceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            resourceLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            resourceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 6),
            resourceLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -6),
            containerView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return containerView
    }
    
    private func createCraftButton(recipe: Recipe, resultItem: Item?) -> ActionButtonSmallView {
        let button = ActionButtonSmallView(craftButton: resultItem) { [weak self] in
            self?.craftButtonTapped()
        }
        
        return button
    }
}

// MARK: - Helper Methods

extension SmithingViewController {
    private func getLevelColor(level: Int) -> UIColor {
        switch level {
        case 1: return .systemGreen
        case 2: return .systemBlue
        case 3: return .systemPurple
        case 4: return .systemOrange
        case 5: return .systemRed
        default: return .white
        }
    }
    
    private func getRecipeCardBackgroundColor(recipe: Recipe, isCraftable: Bool, isSelected: Bool) -> UIColor {
        if isSelected {
            let itemReader = ItemReader.shared
            let resultItem = itemReader.getItem(by: recipe.resultItemId)
            let itemColor = ActionButtonSmallView.convertSwiftUIColorToUIColor(resultItem?.color() ?? Color.white)
            return itemColor.withAlphaComponent(0.3)
        } else if recipe.isUnknown || !isCraftable {
            return UIColor.black.withAlphaComponent(0.4)
        } else {
            return UIColor.black.withAlphaComponent(0.6)
        }
    }
    
    private func isRecipeCraftable(_ recipe: Recipe) -> Bool {
        return viewModel.craftableRecipes.contains(where: { $0.id == recipe.id }) && !recipe.isUnknown
    }
    
    private func getRecipeFromView(_ view: UIView) -> Recipe? {
        guard let recipeIdString = view.accessibilityIdentifier,
              let recipeId = Int(recipeIdString) else { return nil }
        
        return viewModel.availableRecipes.first { $0.id == recipeId }
    }
    
    private func clearCraftingContent() {
        craftingStackView.arrangedSubviews.forEach { 
            craftingStackView.removeArrangedSubview($0)
            $0.removeFromSuperview() 
        }
    }
}

// MARK: - ActionButtonSmallView Extensions

extension ActionButtonSmallView {
    convenience init(filterType: ItemType, onTap: (() -> Void)? = nil) {
        let icon: String
        let color: UIColor
        
        switch filterType {
        case .weapon:
            icon = "sword.katana"
            color = .systemOrange
        case .armor:
            icon = "shield.fill"
            color = .systemBlue
        default:
            icon = "questionmark.circle"
            color = .systemGray
        }
        
        self.init(title: filterType.rawValue.capitalized, icon: icon, color: color, onTap: onTap)
        self.accessibilityIdentifier = filterType.rawValue
        
        // Remove the fixed width constraint for filter buttons
        disableFixedWidthConstraint()
        
        // Add flexible width constraints
        self.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        self.widthAnchor.constraint(lessThanOrEqualToConstant: 90).isActive = true
    }
    
    convenience init(knownFilter: Bool, onTap: (() -> Void)? = nil) {
        self.init(title: "Known", icon: "book.fill", color: .systemGreen, onTap: onTap)
        self.accessibilityIdentifier = "known"
        
        // Remove the fixed width constraint for filter buttons
        disableFixedWidthConstraint()
        
        // Add flexible width constraints
        self.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        self.widthAnchor.constraint(lessThanOrEqualToConstant: 80).isActive = true
    }
    
    convenience init(craftButton item: Item?, onTap: (() -> Void)? = nil) {
        let color = item != nil ? Self.convertSwiftUIColorToUIColor(item!.color()) : .systemGray
        self.init(title: "🔨 Craft", icon: "hammer.fill", color: color, onTap: onTap)
        
        // Remove the fixed width constraint for craft button too
        disableFixedWidthConstraint()
        
        // Add flexible width constraint for craft button (уменьшаю максимальную ширину)
        self.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        self.widthAnchor.constraint(lessThanOrEqualToConstant: 140).isActive = true
    }
    
    // Helper function to disable the fixed width constraint
    private func disableFixedWidthConstraint() {
        // Найти и отключить constraint с шириной 110
        for constraint in constraints {
            if constraint.firstAttribute == .width && constraint.constant == 110 {
                constraint.isActive = false
                break
            }
        }
    }
    
    // Helper function for color conversion
    static func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
        if color == .red { return .systemRed }
        if color == .blue { return .systemBlue }
        if color == .green { return .systemGreen }
        if color == .purple { return .systemPurple }
        if color == .orange { return .systemOrange }
        if color == .yellow { return .systemYellow }
        if color == .pink { return .systemPink }
        if color == .cyan { return .systemCyan }
        if color == .mint { return .systemMint }
        if color == .teal { return .systemTeal }
        if color == .indigo { return .systemIndigo }
        return .white
    }
} 