import UIKit
import SwiftUI
import Combine

// Simple item group for display
struct InventoryItemGroup {
    let items: [Item]
    let name: String
    let count: Int
    let cost: Int
    let icon: String
    let color: UIColor
    
    init(items: [Item]) {
        self.items = items
        self.name = items[0].name
        self.count = items.count
        self.cost = items[0].cost
        self.icon = items[0].icon()
        self.color = UIColor(items[0].color())
    }
}

// Simple table view cell
class InventoryTableViewCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let costLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 8
        contentView.addSubview(containerView)
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        // Name label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor(Theme.textColor)
        containerView.addSubview(nameLabel)
        
        // Cost label
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        costLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        costLabel.textColor = .green
        containerView.addSubview(costLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: costLabel.leadingAnchor, constant: -8),
            
            costLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            costLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            costLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    
    func configure(with group: InventoryItemGroup, isSelected: Bool) {
        iconImageView.image = UIImage(systemName: group.icon)
        iconImageView.tintColor = group.color
        
        nameLabel.text = group.count > 1 ? "\(group.name) (\(group.count))" : group.name
        costLabel.text = "\(group.cost)"
        
        containerView.backgroundColor = isSelected ? 
            UIColor(Theme.awarenessProgressColor).withAlphaComponent(0.3) : 
            UIColor.black.withAlphaComponent(0.8)
    }
}

class CharacterInventoryViewController: UIViewController {
    
    // MARK: - Properties
    private var character: any Character
    private let scene: Scene
    private let mainViewModel: MainSceneViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let backgroundImageView = UIImageView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    // Main content
    private let mainContainerView = UIView()
    private let characterWidgetContainer = UIView()
    private var characterWidgetHostingController: UIHostingController<AnyView>?
    
    // Inventory components
    private let inventoryContainerView = UIView()
    private let filterHeaderView = UIView()
    private let tableView = UITableView()
    private let coinsFooterView = UIView()
    private let coinsLabel = UILabel()
    
    // Filter buttons
    private let filterScrollView = UIScrollView()
    private let filterStackView = UIStackView()
    private var filterButtons: [UIButton] = []
    
    // Data
    private var inventoryItems: [InventoryItemGroup] = []
    private var selectedItemType: ItemType? = nil
    private var selectedItems: [Item] = []
    
    // MARK: - Initialization
    init(character: any Character, scene: Scene, mainViewModel: MainSceneViewModel) {
        self.character = character
        self.scene = scene
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.clipsToBounds = false
        
        setupBackgroundImage()
        setupDustEffect()
        setupTopWidget()
        setupMainLayout()
        setupInventoryComponents()
        updateInventoryContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Background и dust effect теперь управляются constraints - никаких костылей не нужно
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshCharacterData()
        updateInventoryContent()
    }
    
    // MARK: - Setup Methods
    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        let imageName = "location\(scene.id)"
        backgroundImageView.image = UIImage(named: imageName) ?? UIImage(named: "MainSceneBackground")!
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // Привязываем к полному размеру view (не safe area) с небольшим отступом для покрытия всех краев
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: -20),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -20),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20)
        ])
    }
    
    private func setupDustEffect() {
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(dustViewHostingController)
        view.insertSubview(dustViewHostingController.view, aboveSubview: backgroundImageView)
        
        // Используем constraints вместо frame-based layout
        NSLayoutConstraint.activate([
            dustViewHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            dustViewHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dustViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dustViewHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
    }
    
    private func setupTopWidget() {
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        topWidgetContainerView.backgroundColor = .clear
        view.addSubview(topWidgetContainerView)
        
        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC
        
        NSLayoutConstraint.activate([
            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),
            
            widgetVC.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor),
            widgetVC.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor),
            widgetVC.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor),
            widgetVC.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor)
        ])
    }
    
    private func setupMainLayout() {
        // Main container
        mainContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainerView)
        
        // Character widget container
        characterWidgetContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(characterWidgetContainer)
        
        // Inventory container
        inventoryContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(inventoryContainerView)
        
        // Setup character widget
        setupCharacterWidget()
        
        // Layout constraints
        NSLayoutConstraint.activate([
            mainContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            mainContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            mainContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            mainContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            characterWidgetContainer.topAnchor.constraint(equalTo: mainContainerView.topAnchor),
            characterWidgetContainer.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor),
            characterWidgetContainer.widthAnchor.constraint(equalToConstant: 200),
            characterWidgetContainer.bottomAnchor.constraint(lessThanOrEqualTo: mainContainerView.bottomAnchor),
            
            inventoryContainerView.topAnchor.constraint(equalTo: mainContainerView.topAnchor),
            inventoryContainerView.leadingAnchor.constraint(equalTo: characterWidgetContainer.trailingAnchor, constant: 16),
            inventoryContainerView.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor),
            inventoryContainerView.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor)
        ])
    }
    
    private func setupCharacterWidget() {
        let characterView: AnyView
        if let player = character as? Player {
            characterView = AnyView(PlayerWidget(player: player))
        } else if let npc = character as? NPC {
            characterView = AnyView(HorizontalNPCWidget(npc: npc))
        } else {
            characterView = AnyView(EmptyView())
        }
        
        let hostingController = UIHostingController(rootView: characterView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        characterWidgetContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: characterWidgetContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: characterWidgetContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: characterWidgetContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(lessThanOrEqualTo: characterWidgetContainer.bottomAnchor)
        ])
        
        self.characterWidgetHostingController = hostingController
    }
    
    private func setupInventoryComponents() {
        // Filter header
        filterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        filterHeaderView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        filterHeaderView.layer.cornerRadius = 12
        inventoryContainerView.addSubview(filterHeaderView)
        
        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(InventoryTableViewCell.self, forCellReuseIdentifier: "InventoryCell")
        inventoryContainerView.addSubview(tableView)
        
        // Coins footer
        coinsFooterView.translatesAutoresizingMaskIntoConstraints = false
        coinsFooterView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        coinsFooterView.layer.cornerRadius = 12
        inventoryContainerView.addSubview(coinsFooterView)
        
        // Setup filter buttons
        setupFilterButtons()
        
        // Setup coins display
        setupCoinsDisplay()
        
        // Layout constraints - SIMPLE AND CLEAR
        NSLayoutConstraint.activate([
            // Filter header - fixed height at top
            filterHeaderView.topAnchor.constraint(equalTo: inventoryContainerView.topAnchor),
            filterHeaderView.leadingAnchor.constraint(equalTo: inventoryContainerView.leadingAnchor),
            filterHeaderView.trailingAnchor.constraint(equalTo: inventoryContainerView.trailingAnchor),
            filterHeaderView.heightAnchor.constraint(equalToConstant: 40),
            
            // Coins footer - fixed height at bottom
            coinsFooterView.bottomAnchor.constraint(equalTo: inventoryContainerView.bottomAnchor),
            coinsFooterView.leadingAnchor.constraint(equalTo: inventoryContainerView.leadingAnchor),
            coinsFooterView.trailingAnchor.constraint(equalTo: inventoryContainerView.trailingAnchor),
            coinsFooterView.heightAnchor.constraint(equalToConstant: 40),
            
            // Table view - fills space between header and footer
            tableView.topAnchor.constraint(equalTo: filterHeaderView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: inventoryContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: inventoryContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: coinsFooterView.topAnchor, constant: -8)
        ])
    }
    
    private func setupFilterButtons() {
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.showsHorizontalScrollIndicator = false
        filterHeaderView.addSubview(filterScrollView)
        
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.axis = .horizontal
        filterStackView.spacing = 10
        filterScrollView.addSubview(filterStackView)
        
        // Create "All" button
        let allButton = createFilterButton(systemName: "tag", type: nil)
        filterButtons.append(allButton)
        filterStackView.addArrangedSubview(allButton)
        
        // Create buttons for each item type
        for (index, itemType) in ItemType.allCases.enumerated() {
            let button = createFilterButton(systemName: itemType.icon, type: itemType)
            button.tag = index
            filterButtons.append(button)
            filterStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            filterScrollView.topAnchor.constraint(equalTo: filterHeaderView.topAnchor, constant: 5),
            filterScrollView.leadingAnchor.constraint(equalTo: filterHeaderView.leadingAnchor, constant: 8),
            filterScrollView.trailingAnchor.constraint(equalTo: filterHeaderView.trailingAnchor, constant: -8),
            filterScrollView.bottomAnchor.constraint(equalTo: filterHeaderView.bottomAnchor, constant: -5),
            
            filterStackView.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStackView.heightAnchor.constraint(equalTo: filterScrollView.heightAnchor)
        ])
        
        updateFilterButtonAppearance()
    }
    
    private func createFilterButton(systemName: String, type: ItemType?) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        
        if type == nil {
            button.tag = -1 // "All" button
        }
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return button
    }
    
    private func setupCoinsDisplay() {
        let coinsIconImageView = UIImageView()
        coinsIconImageView.translatesAutoresizingMaskIntoConstraints = false
        coinsIconImageView.image = UIImage(systemName: "cedisign")
        coinsIconImageView.tintColor = .green
        coinsIconImageView.contentMode = .scaleAspectFit
        coinsFooterView.addSubview(coinsIconImageView)
        
        coinsLabel.translatesAutoresizingMaskIntoConstraints = false
        coinsLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        coinsLabel.textColor = .green
        coinsLabel.text = "\(character.coins.value)"
        coinsFooterView.addSubview(coinsLabel)
        
        NSLayoutConstraint.activate([
            coinsIconImageView.leadingAnchor.constraint(equalTo: coinsFooterView.leadingAnchor, constant: 10),
            coinsIconImageView.centerYAnchor.constraint(equalTo: coinsFooterView.centerYAnchor),
            coinsIconImageView.widthAnchor.constraint(equalToConstant: 16),
            coinsIconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            coinsLabel.leadingAnchor.constraint(equalTo: coinsIconImageView.trailingAnchor, constant: 8),
            coinsLabel.centerYAnchor.constraint(equalTo: coinsFooterView.centerYAnchor),
            coinsLabel.trailingAnchor.constraint(lessThanOrEqualTo: coinsFooterView.trailingAnchor, constant: -10)
        ])
    }
    
    // MARK: - Actions
    @objc private func filterButtonTapped(_ sender: UIButton) {
        if sender.tag == -1 {
            selectedItemType = nil
        } else if sender.tag >= 0 && sender.tag < ItemType.allCases.count {
            selectedItemType = ItemType.allCases[sender.tag]
        }
        
        updateFilterButtonAppearance()
        updateInventoryContent()
    }
    
    private func updateFilterButtonAppearance() {
        for button in filterButtons {
            let isSelected: Bool
            if button.tag == -1 {
                isSelected = selectedItemType == nil
            } else if button.tag >= 0 && button.tag < ItemType.allCases.count {
                isSelected = selectedItemType == ItemType.allCases[button.tag]
            } else {
                isSelected = false
            }
            
            button.tintColor = isSelected ? .yellow : UIColor(Theme.textColor)
        }
    }
    
    // MARK: - Data Updates
    public func updateInventoryContent() {
        let filteredItems = selectedItemType == nil ? 
            character.items : 
            character.items.filter { $0.type == selectedItemType }
        
        inventoryItems = Dictionary(grouping: filteredItems, by: { $0.id.description })
            .map { InventoryItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        coinsLabel.text = "\(character.coins.value)"
    }
    
    public func refreshCharacterData() {
        if let _ = character as? Player {
            if let currentPlayer = GameStateService.shared.player {
                character = currentPlayer
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleItemTap(_ group: InventoryItemGroup) {
        guard let item = group.items.first else { return }
        
        selectItem(item.index)
        
        if item.isConsumable {
            consumeItem(item)
        }
    }
    
    private func selectItem(_ index: Int) {
        if let item = character.items.first(where: { $0.index == index }) {
            if let existingIndex = selectedItems.firstIndex(where: { $0.index == index }) {
                selectedItems.remove(at: existingIndex)
            } else {
                selectedItems.append(item)
            }
            mainViewModel.selectedItemIndex = index
            tableView.reloadData()
        }
    }
    
    private func consumeItem(_ item: Item) {
        guard let player = character as? Player else { return }
        FeedingService.shared.consumeFood(vampire: player, food: item)
        
        if let index = player.items.firstIndex(where: { $0.index == item.index }) {
            player.items.remove(at: index)
            
            if let selectedIndex = selectedItems.firstIndex(where: { $0.index == item.index }) {
                selectedItems.remove(at: selectedIndex)
            }
            
            updateInventoryContent()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CharacterInventoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inventoryItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InventoryCell", for: indexPath) as! InventoryTableViewCell
        let group = inventoryItems[indexPath.row]
        
        let isSelected = selectedItems.contains { selectedItem in
            group.items.contains { $0.index == selectedItem.index }
        }
        
        cell.configure(with: group, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = inventoryItems[indexPath.row]
        handleItemTap(group)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52 // Fixed height for consistency
    }
} 