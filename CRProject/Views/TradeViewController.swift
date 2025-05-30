import UIKit
import SwiftUI
import Combine

// Trade item group for display
struct TradeItemGroup {
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

// Trade table view cell
class TradeTableViewCell: UITableViewCell {
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
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 6),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: costLabel.leadingAnchor, constant: -6),
            
            costLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            costLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            costLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
    }
    
    func configure(with group: TradeItemGroup) {
        iconImageView.image = UIImage(systemName: group.icon)
        iconImageView.tintColor = group.color
        
        nameLabel.text = group.count > 1 ? "\(group.name) (\(group.count))" : group.name
        costLabel.text = "\(group.cost)"
    }
}

class TradeViewController: UIViewController {
    
    // MARK: - Properties
    private var player: Player
    private var npc: NPC
    private let scene: Scene
    private let mainViewModel: MainSceneViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Add dismissal callback
    private var onDismiss: (() -> Void)?
    
    // UI Elements
    private let backgroundImageView = UIImageView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    // Main content
    private let mainContainerView = UIView()
    private let inventoriesStackView = UIStackView()
    
    // Player inventory
    private let playerInventoryContainer = UIView()
    private let playerHeaderView = UIView()
    private let playerCoinsLabel = UILabel()
    private let playerNameLabel = UILabel()
    private let playerFilterScrollView = UIScrollView()
    private let playerFilterStackView = UIStackView()
    private let playerTableView = UITableView()
    private var playerFilterButtons: [UIButton] = []
    
    // NPC inventory
    private let npcInventoryContainer = UIView()
    private let npcHeaderView = UIView()
    private let npcCoinsLabel = UILabel()
    private let npcNameLabel = UILabel()
    private let npcFilterScrollView = UIScrollView()
    private let npcFilterStackView = UIStackView()
    private let npcTableView = UITableView()
    private var npcFilterButtons: [UIButton] = []
    
    // Deal section - replace with ActionButtonSmallView
    private let dealContainer = UIView()
    private var dealButton: ActionButtonSmallView!
    
    // Data
    private var tempPlayerItems: [Item] = []
    private var tempNPCItems: [Item] = []
    private var originalPlayerItems: [Item] = []
    private var originalNPCItems: [Item] = []
    private var dealTotal: Int = 0
    
    // Filtering
    private var playerSortType: ItemType? = nil
    private var npcSortType: ItemType? = nil
    
    // Computed properties for grouped items
    private var groupedPlayerItems: [TradeItemGroup] {
        let items = playerSortType == nil ? tempPlayerItems : tempPlayerItems.filter { $0.type == playerSortType }
        return Dictionary(grouping: items, by: { $0.id.description })
            .map { TradeItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    private var groupedNPCItems: [TradeItemGroup] {
        let items = npcSortType == nil ? tempNPCItems : tempNPCItems.filter { $0.type == npcSortType }
        return Dictionary(grouping: items, by: { $0.id.description })
            .map { TradeItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    // MARK: - Initialization
    init(player: Player, npc: NPC, scene: Scene, mainViewModel: MainSceneViewModel, onDismiss: (() -> Void)? = nil) {
        self.player = player
        self.npc = npc
        self.scene = scene
        self.mainViewModel = mainViewModel
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupBackgroundImage()
        setupDustEffect()
        setupTopWidget()
        setupMainLayout()
        setupInventoryContainers()
        setupDealSection()
        
        initializeTradeData()
        updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBackgroundFrame()
        updateDustEffectFrame()
    }
    
    // MARK: - Setup Methods
    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        let imageName = "location\(scene.id)"
        backgroundImageView.image = UIImage(named: imageName) ?? UIImage(named: "MainSceneBackground")!
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        view.addSubview(backgroundImageView)
    }
    
    private func setupDustEffect() {
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = true
        dustViewHostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addChild(dustViewHostingController)
        view.addSubview(dustViewHostingController.view)
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
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
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
        
        // Inventories stack view
        inventoriesStackView.translatesAutoresizingMaskIntoConstraints = false
        inventoriesStackView.axis = .horizontal
        inventoriesStackView.spacing = 20
        inventoriesStackView.distribution = .fillEqually
        mainContainerView.addSubview(inventoriesStackView)
        
        NSLayoutConstraint.activate([
            mainContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            mainContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            mainContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            mainContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            
            inventoriesStackView.topAnchor.constraint(equalTo: mainContainerView.topAnchor),
            inventoriesStackView.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor),
            inventoriesStackView.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor),
            inventoriesStackView.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor, constant: -80)
        ])
    }
    
    private func setupInventoryContainers() {
        setupPlayerInventory()
        setupNPCInventory()
        
        inventoriesStackView.addArrangedSubview(playerInventoryContainer)
        inventoriesStackView.addArrangedSubview(npcInventoryContainer)
    }
    
    private func setupPlayerInventory() {
        playerInventoryContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        setupPlayerHeader()
        
        // Filter buttons
        setupPlayerFilterButtons()
        
        // Table view
        playerTableView.translatesAutoresizingMaskIntoConstraints = false
        playerTableView.backgroundColor = .clear
        playerTableView.separatorStyle = .none
        playerTableView.showsVerticalScrollIndicator = false
        playerTableView.dataSource = self
        playerTableView.delegate = self
        playerTableView.register(TradeTableViewCell.self, forCellReuseIdentifier: "PlayerTradeCell")
        playerInventoryContainer.addSubview(playerTableView)
        
        // Layout
        NSLayoutConstraint.activate([
            playerHeaderView.topAnchor.constraint(equalTo: playerInventoryContainer.topAnchor),
            playerHeaderView.leadingAnchor.constraint(equalTo: playerInventoryContainer.leadingAnchor),
            playerHeaderView.trailingAnchor.constraint(equalTo: playerInventoryContainer.trailingAnchor),
            playerHeaderView.heightAnchor.constraint(equalToConstant: 30),
            
            playerFilterScrollView.topAnchor.constraint(equalTo: playerHeaderView.bottomAnchor, constant: 2),
            playerFilterScrollView.leadingAnchor.constraint(equalTo: playerInventoryContainer.leadingAnchor),
            playerFilterScrollView.trailingAnchor.constraint(equalTo: playerInventoryContainer.trailingAnchor),
            playerFilterScrollView.heightAnchor.constraint(equalToConstant: 30),
            
            playerTableView.topAnchor.constraint(equalTo: playerFilterScrollView.bottomAnchor, constant: 2),
            playerTableView.leadingAnchor.constraint(equalTo: playerInventoryContainer.leadingAnchor),
            playerTableView.trailingAnchor.constraint(equalTo: playerInventoryContainer.trailingAnchor),
            playerTableView.bottomAnchor.constraint(equalTo: playerInventoryContainer.bottomAnchor)
        ])
    }
    
    private func setupPlayerHeader() {
        playerHeaderView.translatesAutoresizingMaskIntoConstraints = false
        playerHeaderView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        playerHeaderView.layer.cornerRadius = 12
        playerInventoryContainer.addSubview(playerHeaderView)
        
        // Coins icon
        let coinsIconImageView = UIImageView()
        coinsIconImageView.translatesAutoresizingMaskIntoConstraints = false
        coinsIconImageView.image = UIImage(systemName: "cedisign")
        coinsIconImageView.tintColor = .green
        coinsIconImageView.contentMode = .scaleAspectFit
        playerHeaderView.addSubview(coinsIconImageView)
        
        // Coins label
        playerCoinsLabel.translatesAutoresizingMaskIntoConstraints = false
        playerCoinsLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        playerCoinsLabel.textColor = .green
        playerCoinsLabel.text = "\(player.coins.value)"
        playerHeaderView.addSubview(playerCoinsLabel)
        
        // Player icon
        let playerIconImageView = UIImageView()
        playerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        playerIconImageView.image = UIImage(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
        playerIconImageView.tintColor = player.isVampire ? UIColor(Theme.primaryColor) : UIColor(Theme.textColor)
        playerIconImageView.contentMode = .scaleAspectFit
        playerHeaderView.addSubview(playerIconImageView)
        
        // Player name
        playerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        playerNameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        playerNameLabel.textColor = UIColor(Theme.textColor)
        playerNameLabel.text = player.name
        playerHeaderView.addSubview(playerNameLabel)
        
        // Profession icon
        let professionIconImageView = UIImageView()
        professionIconImageView.translatesAutoresizingMaskIntoConstraints = false
        professionIconImageView.image = UIImage(systemName: player.profession.icon)
        professionIconImageView.tintColor = UIColor(player.profession.color)
        professionIconImageView.contentMode = .scaleAspectFit
        playerHeaderView.addSubview(professionIconImageView)
        
        NSLayoutConstraint.activate([
            coinsIconImageView.leadingAnchor.constraint(equalTo: playerHeaderView.leadingAnchor, constant: 10),
            coinsIconImageView.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            coinsIconImageView.widthAnchor.constraint(equalToConstant: 14),
            coinsIconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            playerCoinsLabel.leadingAnchor.constraint(equalTo: coinsIconImageView.trailingAnchor, constant: 4),
            playerCoinsLabel.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            
            professionIconImageView.trailingAnchor.constraint(equalTo: playerHeaderView.trailingAnchor, constant: -10),
            professionIconImageView.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            professionIconImageView.widthAnchor.constraint(equalToConstant: 14),
            professionIconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            playerNameLabel.trailingAnchor.constraint(equalTo: professionIconImageView.leadingAnchor, constant: -4),
            playerNameLabel.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            
            playerIconImageView.trailingAnchor.constraint(equalTo: playerNameLabel.leadingAnchor, constant: -4),
            playerIconImageView.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            playerIconImageView.widthAnchor.constraint(equalToConstant: 14),
            playerIconImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    private func setupPlayerFilterButtons() {
        playerFilterScrollView.translatesAutoresizingMaskIntoConstraints = false
        playerFilterScrollView.showsHorizontalScrollIndicator = false
        playerInventoryContainer.addSubview(playerFilterScrollView)
        
        playerFilterStackView.translatesAutoresizingMaskIntoConstraints = false
        playerFilterStackView.axis = .horizontal
        playerFilterStackView.spacing = 10
        playerFilterScrollView.addSubview(playerFilterStackView)
        
        // Create "All" button
        let allButton = createFilterButton(systemName: "tag", type: nil, isPlayer: true)
        playerFilterButtons.append(allButton)
        playerFilterStackView.addArrangedSubview(allButton)
        
        // Create buttons for each item type
        for (index, itemType) in ItemType.allCases.enumerated() {
            let button = createFilterButton(systemName: itemType.icon, type: itemType, isPlayer: true)
            button.tag = index
            playerFilterButtons.append(button)
            playerFilterStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            playerFilterStackView.topAnchor.constraint(equalTo: playerFilterScrollView.topAnchor),
            playerFilterStackView.leadingAnchor.constraint(equalTo: playerFilterScrollView.leadingAnchor, constant: 8),
            playerFilterStackView.trailingAnchor.constraint(equalTo: playerFilterScrollView.trailingAnchor, constant: -8),
            playerFilterStackView.bottomAnchor.constraint(equalTo: playerFilterScrollView.bottomAnchor)
        ])
        
        updatePlayerFilterButtonAppearance()
    }
    
    private func setupNPCInventory() {
        npcInventoryContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        setupNPCHeader()
        
        // Filter buttons
        setupNPCFilterButtons()
        
        // Table view
        npcTableView.translatesAutoresizingMaskIntoConstraints = false
        npcTableView.backgroundColor = .clear
        npcTableView.separatorStyle = .none
        npcTableView.showsVerticalScrollIndicator = false
        npcTableView.dataSource = self
        npcTableView.delegate = self
        npcTableView.register(TradeTableViewCell.self, forCellReuseIdentifier: "NPCTradeCell")
        npcInventoryContainer.addSubview(npcTableView)
        
        // Layout
        NSLayoutConstraint.activate([
            npcHeaderView.topAnchor.constraint(equalTo: npcInventoryContainer.topAnchor),
            npcHeaderView.leadingAnchor.constraint(equalTo: npcInventoryContainer.leadingAnchor),
            npcHeaderView.trailingAnchor.constraint(equalTo: npcInventoryContainer.trailingAnchor),
            npcHeaderView.heightAnchor.constraint(equalToConstant: 30),
            
            npcFilterScrollView.topAnchor.constraint(equalTo: npcHeaderView.bottomAnchor, constant: 2),
            npcFilterScrollView.leadingAnchor.constraint(equalTo: npcInventoryContainer.leadingAnchor),
            npcFilterScrollView.trailingAnchor.constraint(equalTo: npcInventoryContainer.trailingAnchor),
            npcFilterScrollView.heightAnchor.constraint(equalToConstant: 30),
            
            npcTableView.topAnchor.constraint(equalTo: npcFilterScrollView.bottomAnchor, constant: 2),
            npcTableView.leadingAnchor.constraint(equalTo: npcInventoryContainer.leadingAnchor),
            npcTableView.trailingAnchor.constraint(equalTo: npcInventoryContainer.trailingAnchor),
            npcTableView.bottomAnchor.constraint(equalTo: npcInventoryContainer.bottomAnchor)
        ])
    }
    
    private func setupNPCHeader() {
        npcHeaderView.translatesAutoresizingMaskIntoConstraints = false
        npcHeaderView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        npcHeaderView.layer.cornerRadius = 12
        npcInventoryContainer.addSubview(npcHeaderView)
        
        // NPC icon
        let npcIconImageView = UIImageView()
        npcIconImageView.translatesAutoresizingMaskIntoConstraints = false
        npcIconImageView.image = UIImage(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
        npcIconImageView.tintColor = UIColor(Theme.textColor)
        npcIconImageView.contentMode = .scaleAspectFit
        npcHeaderView.addSubview(npcIconImageView)
        
        // NPC name
        npcNameLabel.translatesAutoresizingMaskIntoConstraints = false
        npcNameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        npcNameLabel.textColor = UIColor(Theme.textColor)
        npcNameLabel.text = npc.name
        npcHeaderView.addSubview(npcNameLabel)
        
        // Profession icon
        let professionIconImageView = UIImageView()
        professionIconImageView.translatesAutoresizingMaskIntoConstraints = false
        professionIconImageView.image = UIImage(systemName: npc.profession.icon)
        professionIconImageView.tintColor = UIColor(npc.profession.color)
        professionIconImageView.contentMode = .scaleAspectFit
        npcHeaderView.addSubview(professionIconImageView)
        
        // Coins icon
        let coinsIconImageView = UIImageView()
        coinsIconImageView.translatesAutoresizingMaskIntoConstraints = false
        coinsIconImageView.image = UIImage(systemName: "cedisign")
        coinsIconImageView.tintColor = .green
        coinsIconImageView.contentMode = .scaleAspectFit
        npcHeaderView.addSubview(coinsIconImageView)
        
        // Coins label
        npcCoinsLabel.translatesAutoresizingMaskIntoConstraints = false
        npcCoinsLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        npcCoinsLabel.textColor = .green
        npcCoinsLabel.text = "\(npc.coins.value)"
        npcHeaderView.addSubview(npcCoinsLabel)
        
        NSLayoutConstraint.activate([
            npcIconImageView.leadingAnchor.constraint(equalTo: npcHeaderView.leadingAnchor, constant: 10),
            npcIconImageView.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            npcIconImageView.widthAnchor.constraint(equalToConstant: 14),
            npcIconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            npcNameLabel.leadingAnchor.constraint(equalTo: npcIconImageView.trailingAnchor, constant: 4),
            npcNameLabel.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            
            professionIconImageView.leadingAnchor.constraint(equalTo: npcNameLabel.trailingAnchor, constant: 4),
            professionIconImageView.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            professionIconImageView.widthAnchor.constraint(equalToConstant: 14),
            professionIconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            npcCoinsLabel.trailingAnchor.constraint(equalTo: npcHeaderView.trailingAnchor, constant: -10),
            npcCoinsLabel.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            
            coinsIconImageView.trailingAnchor.constraint(equalTo: npcCoinsLabel.leadingAnchor, constant: -4),
            coinsIconImageView.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            coinsIconImageView.widthAnchor.constraint(equalToConstant: 14),
            coinsIconImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    private func setupNPCFilterButtons() {
        npcFilterScrollView.translatesAutoresizingMaskIntoConstraints = false
        npcFilterScrollView.showsHorizontalScrollIndicator = false
        npcInventoryContainer.addSubview(npcFilterScrollView)
        
        npcFilterStackView.translatesAutoresizingMaskIntoConstraints = false
        npcFilterStackView.axis = .horizontal
        npcFilterStackView.spacing = 10
        npcFilterScrollView.addSubview(npcFilterStackView)
        
        // Create "All" button
        let allButton = createFilterButton(systemName: "tag", type: nil, isPlayer: false)
        npcFilterButtons.append(allButton)
        npcFilterStackView.addArrangedSubview(allButton)
        
        // Create buttons for each item type
        for (index, itemType) in ItemType.allCases.enumerated() {
            let button = createFilterButton(systemName: itemType.icon, type: itemType, isPlayer: false)
            button.tag = index
            npcFilterButtons.append(button)
            npcFilterStackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            npcFilterStackView.topAnchor.constraint(equalTo: npcFilterScrollView.topAnchor),
            npcFilterStackView.leadingAnchor.constraint(equalTo: npcFilterScrollView.leadingAnchor, constant: 8),
            npcFilterStackView.trailingAnchor.constraint(equalTo: npcFilterScrollView.trailingAnchor, constant: -8),
            npcFilterStackView.bottomAnchor.constraint(equalTo: npcFilterScrollView.bottomAnchor)
        ])
        
        updateNPCFilterButtonAppearance()
    }
    
    private func setupDealSection() {
        dealContainer.translatesAutoresizingMaskIntoConstraints = false
        dealContainer.isHidden = true // Initially hidden since deal total is 0
        mainContainerView.addSubview(dealContainer)
        
        // Create ActionButtonSmallView with proper callback
        dealButton = ActionButtonSmallView(
            title: "Deal 0",
            icon: "cedisign",
            color: .green,
            onTap: { [weak self] in
                self?.makeADeal()
                self?.onDismiss?()
            }
        )
        dealButton.translatesAutoresizingMaskIntoConstraints = false
        dealButton.isEnabled = couldMakeADeal()
        dealButton.alpha = couldMakeADeal() ? 1.0 : 0.5
        dealContainer.addSubview(dealButton)
        
        NSLayoutConstraint.activate([
            dealContainer.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor),
            dealContainer.centerXAnchor.constraint(equalTo: mainContainerView.centerXAnchor),
            dealContainer.widthAnchor.constraint(equalToConstant: 200),
            dealContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Center the button in the container instead of stretching it
            dealButton.centerXAnchor.constraint(equalTo: dealContainer.centerXAnchor),
            dealButton.centerYAnchor.constraint(equalTo: dealContainer.centerYAnchor)
        ])
    }
    
    private func createFilterButton(systemName: String, type: ItemType?, isPlayer: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        
        if isPlayer {
            button.addTarget(self, action: #selector(playerFilterButtonTapped(_:)), for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(npcFilterButtonTapped(_:)), for: .touchUpInside)
        }
        
        if type == nil {
            button.tag = -1 // "All" button
        }
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return button
    }
    
    // MARK: - Actions
    @objc private func playerFilterButtonTapped(_ sender: UIButton) {
        if sender.tag == -1 {
            playerSortType = nil
        } else if sender.tag >= 0 && sender.tag < ItemType.allCases.count {
            playerSortType = ItemType.allCases[sender.tag]
        }
        
        updatePlayerFilterButtonAppearance()
        playerTableView.reloadData()
    }
    
    @objc private func npcFilterButtonTapped(_ sender: UIButton) {
        if sender.tag == -1 {
            npcSortType = nil
        } else if sender.tag >= 0 && sender.tag < ItemType.allCases.count {
            npcSortType = ItemType.allCases[sender.tag]
        }
        
        updateNPCFilterButtonAppearance()
        npcTableView.reloadData()
    }
    
    // MARK: - Helper Methods
    private func updateBackgroundFrame() {
        let extraSpace: CGFloat = 100
        backgroundImageView.frame = CGRect(
            x: -extraSpace / 2,
            y: -extraSpace / 2,
            width: view.bounds.width + extraSpace,
            height: view.bounds.height + extraSpace
        )
        view.sendSubviewToBack(backgroundImageView)
    }
    
    private func updateDustEffectFrame() {
        dustEffectView?.view.frame = view.bounds
        if let dustView = dustEffectView?.view {
            view.insertSubview(dustView, aboveSubview: backgroundImageView)
        }
    }
    
    private func updatePlayerFilterButtonAppearance() {
        for button in playerFilterButtons {
            let isSelected: Bool
            if button.tag == -1 {
                isSelected = playerSortType == nil
            } else if button.tag >= 0 && button.tag < ItemType.allCases.count {
                isSelected = playerSortType == ItemType.allCases[button.tag]
            } else {
                isSelected = false
            }
            
            button.tintColor = isSelected ? .yellow : UIColor(Theme.textColor)
        }
    }
    
    private func updateNPCFilterButtonAppearance() {
        for button in npcFilterButtons {
            let isSelected: Bool
            if button.tag == -1 {
                isSelected = npcSortType == nil
            } else if button.tag >= 0 && button.tag < ItemType.allCases.count {
                isSelected = npcSortType == ItemType.allCases[button.tag]
            } else {
                isSelected = false
            }
            
            button.tintColor = isSelected ? .yellow : UIColor(Theme.textColor)
        }
    }
    
    private func initializeTradeData() {
        tempPlayerItems = player.items
        tempNPCItems = npc.items
        originalPlayerItems = player.items
        originalNPCItems = npc.items
        updateDealTotal()
    }
    
    private func updateUI() {
        playerCoinsLabel.text = "\(player.coins.value)"
        npcCoinsLabel.text = "\(npc.coins.value)"
        playerTableView.reloadData()
        npcTableView.reloadData()
        updateDealButton()
    }
    
    private func updateDealTotal() {
        // Items moved from player to NPC
        let playerToNPC = originalPlayerItems.filter { original in !tempPlayerItems.contains(where: { $0.index == original.index }) }
        let npcToPlayer = originalNPCItems.filter { original in !tempNPCItems.contains(where: { $0.index == original.index }) }
        let playerValue = playerToNPC.reduce(0) { $0 + $1.cost }
        let npcValue = npcToPlayer.reduce(0) { $0 + $1.cost }
        dealTotal = playerValue - npcValue
        
        updateDealButton()
    }
    
    private func updateDealButton() {
        // Hide deal container if deal total is 0
        if dealTotal == 0 {
            dealContainer.isHidden = true
            return
        }
        
        // Show deal container if hidden
        dealContainer.isHidden = false
        
        let dealText = "Deal \(dealTotal)"
        let dealColor: UIColor = dealTotal >= 0 ? .green : .red
        
        // Remove old button and create new one with updated values
        dealButton.removeFromSuperview()
        dealButton = ActionButtonSmallView(
            title: dealText,
            icon: "cedisign",
            color: dealColor,
            onTap: { [weak self] in
                self?.makeADeal()
                self?.onDismiss?()
            }
        )
        dealButton.translatesAutoresizingMaskIntoConstraints = false
        dealButton.isEnabled = couldMakeADeal()
        dealButton.alpha = couldMakeADeal() ? 1.0 : 0.5
        dealContainer.addSubview(dealButton)
        
        NSLayoutConstraint.activate([
            // Center the button in the container instead of stretching it
            dealButton.centerXAnchor.constraint(equalTo: dealContainer.centerXAnchor),
            dealButton.centerYAnchor.constraint(equalTo: dealContainer.centerYAnchor)
        ])
    }
    
    private func couldMakeADeal() -> Bool {
        if dealTotal > 0 {
            return npc.coins.value >= dealTotal
        } else {
            return player.coins.value >= abs(dealTotal)
        }
    }
    
    private func moveItemFromPlayerToNPC(_ group: TradeItemGroup) {
        guard let firstItem = group.items.first else { return }
        if let index = tempPlayerItems.firstIndex(where: { $0.index == firstItem.index }) {
            let item = tempPlayerItems.remove(at: index)
            tempNPCItems.append(item)
            updateDealTotal()
            updateUI()
        }
    }
    
    private func moveItemFromNPCToPlayer(_ group: TradeItemGroup) {
        guard let firstItem = group.items.first else { return }
        if let index = tempNPCItems.firstIndex(where: { $0.index == firstItem.index }) {
            let item = tempNPCItems.remove(at: index)
            tempPlayerItems.append(item)
            updateDealTotal()
            updateUI()
        }
    }
    
    private func makeADeal() {
        player.items = tempPlayerItems
        npc.items = tempNPCItems
        
        // Update coins
        if dealTotal > 0 {
            npc.coins.value -= dealTotal
            player.coins.value += dealTotal
        } else {
            player.coins.value -= abs(dealTotal)
            npc.coins.value += abs(dealTotal)
        }
        
        npc.playerRelationship.increase(amount: 1)
        
        if abs(dealTotal) >= 500 && abs(dealTotal) < 1000 {
            StatisticsService.shared.increase500CoinsDeals()
        } else if abs(dealTotal) >= 1000 {
            StatisticsService.shared.increase1000CoinsDeals()
        }
        
        npc.isBeasyByPlayerAction = true
        
        StatisticsService.shared.increaseBartersCompleted()
        NPCInteractionManager.shared.playerInteracted(with: npc)
        GameEventsBusService.shared.addMessageWithIcon(
            type: .common,
            location: GameStateService.shared.currentScene?.name ?? "Unknown",
            player: player,
            secondaryNPC: npc,
            interactionType: NPCInteraction.trade,
            hasSuccess: false,
            isSuccess: nil
        )
        GameTimeService.shared.advanceMinutes(minutes: 10)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension TradeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == playerTableView {
            return groupedPlayerItems.count
        } else {
            return groupedNPCItems.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == playerTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerTradeCell", for: indexPath) as! TradeTableViewCell
            let group = groupedPlayerItems[indexPath.row]
            cell.configure(with: group)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NPCTradeCell", for: indexPath) as! TradeTableViewCell
            let group = groupedNPCItems[indexPath.row]
            cell.configure(with: group)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == playerTableView {
            let group = groupedPlayerItems[indexPath.row]
            moveItemFromPlayerToNPC(group)
        } else {
            let group = groupedNPCItems[indexPath.row]
            moveItemFromNPCToPlayer(group)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
} 