import UIKit
import SwiftUI
import Combine

// MARK: - BackgroundImageViewController
class BackgroundImageViewController: UIViewController {
    // Background components
    private(set) var backgroundImageView = UIImageView()
    private(set) var overlayView = UIView()
    private(set) var dustEffectView: UIHostingController<DustEmitterView>?
    
    private var scene: Scene
    
    init(scene: Scene) {
        self.scene = scene
        super.init(nibName: nil, bundle: nil)
        
        // Настройка полноэкранного режима
        modalPresentationStyle = .overFullScreen
        
        // Важно: включаем расширение на всю область, включая Safe Area
        edgesForExtendedLayout = .all
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Базовый чёрный фон (будет виден в крайнем случае, если что-то пойдёт не так)
        view.backgroundColor = .black
        
        // Первоначальная настройка элементов
        setupBackground()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Получаем максимальную доступную область
        let viewport = view.bounds
        
        // Увеличиваем размер на 100 пикселей во всех направлениях, чтобы гарантированно покрыть всю область
        let extraSpace: CGFloat = 100
        let expandedFrame = CGRect(
            x: -extraSpace/2,
            y: -extraSpace/2,
            width: viewport.width + extraSpace,
            height: viewport.height + extraSpace
        )
        
        // Применяем расширенный размер к фоновому изображению
        backgroundImageView.frame = expandedFrame
        
        // Устанавливаем размеры затемняющего слоя на область всего экрана
        overlayView.frame = viewport
        
        // Dust effect должен занимать весь экран
        dustEffectView?.view.frame = viewport
    }
    
    private func setupBackground() {
        // 1. Настройка фонового изображения
        let imageName = "location\(scene.id.description)"
        let backgroundImage = UIImage(named: imageName) ?? UIImage(named: "MainSceneBackground")!
        
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleAspectFill
        // Важно: разрешаем выход за пределы границ
        backgroundImageView.clipsToBounds = false
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // 2. Добавляем полупрозрачный оверлей
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        view.sendSubviewToBack(overlayView)
        
        // 3. Добавляем эффект пыли
        let dustView = UIHostingController(rootView: DustEmitterView())
        dustView.view.backgroundColor = .clear
        dustView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(dustView)
        view.addSubview(dustView.view)
        dustView.didMove(toParent: self)
        self.dustEffectView = dustView
    }
}

// MARK: - LootViewController
class LootViewController: BackgroundImageViewController {
    // MARK: - Properties
    private let player: Player
    private let npc: NPC
    private let mainViewModel: MainSceneViewModel
    
    // UI Components
    private let npcContainerView = UIView()
    private let playerContainerView = UIView()
    private let npcHeaderView = UIView()
    private let playerHeaderView = UIView()
    private let npcItemsTableView = UITableView()
    private let playerItemsTableView = UITableView()
    
    // Data
    private var npcItems: [ItemGroup] = []
    private var playerItems: [ItemGroup] = []
    
    // MARK: - Initializers
    init(player: Player, npc: NPC, scene: Scene, mainViewModel: MainSceneViewModel) {
        self.player = player
        self.npc = npc
        self.mainViewModel = mainViewModel
        super.init(scene: scene)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContainers()
        setupTableViews()
        setupConstraints()
        updateItemGroups()
        setupSwipeGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateItemGroups()
    }
    
    // MARK: - Setup
    private func setupContainers() {
        // Player Container (LEFT)
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        playerContainerView.layer.cornerRadius = 12
        view.addSubview(playerContainerView)
        
        // Player Header - более информативный заголовок в стиле виджета
        playerHeaderView.translatesAutoresizingMaskIntoConstraints = false
        playerHeaderView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        playerHeaderView.layer.cornerRadius = 12
        
        // Настраиваем информацию о персонаже
        let coinImageView = UIImageView(image: UIImage(systemName: "cedisign"))
        coinImageView.tintColor = .green
        coinImageView.translatesAutoresizingMaskIntoConstraints = false
        coinImageView.contentMode = .scaleAspectFit
        
        let coinsLabel = UILabel()
        coinsLabel.text = "\(player.coins.value)"
        coinsLabel.textColor = .green
        if let font = UIFont(name: "Optima", size: 12) {
            coinsLabel.font = font
        }
        coinsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let sexIcon = UIImageView(image: UIImage(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave"))
        sexIcon.tintColor = player.isVampire ? UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) : .white
        sexIcon.contentMode = .scaleAspectFit
        sexIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = player.name
        nameLabel.textColor = .white
        if let font = UIFont(name: "Optima", size: 12) {
            nameLabel.font = font
        }
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let professionIcon = UIImageView(image: UIImage(systemName: player.profession.icon))
        // Преобразуем SwiftUI Color в UIColor
        if let color = UIColor(player.profession.color) {
            professionIcon.tintColor = color
        } else {
            professionIcon.tintColor = .white
        }
        professionIcon.contentMode = .scaleAspectFit
        professionIcon.translatesAutoresizingMaskIntoConstraints = false
        
        playerHeaderView.addSubview(coinImageView)
        playerHeaderView.addSubview(coinsLabel)
        playerHeaderView.addSubview(sexIcon)
        playerHeaderView.addSubview(nameLabel)
        playerHeaderView.addSubview(professionIcon)
        
        // Устанавливаем констрейнты для элементов заголовка игрока
        NSLayoutConstraint.activate([
            coinImageView.leadingAnchor.constraint(equalTo: playerHeaderView.leadingAnchor, constant: 10),
            coinImageView.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            coinImageView.widthAnchor.constraint(equalToConstant: 14),
            coinImageView.heightAnchor.constraint(equalToConstant: 14),
            
            coinsLabel.leadingAnchor.constraint(equalTo: coinImageView.trailingAnchor, constant: 4),
            coinsLabel.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            
            professionIcon.trailingAnchor.constraint(equalTo: playerHeaderView.trailingAnchor, constant: -10),
            professionIcon.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            professionIcon.widthAnchor.constraint(equalToConstant: 16),
            professionIcon.heightAnchor.constraint(equalToConstant: 16),
            
            nameLabel.trailingAnchor.constraint(equalTo: professionIcon.leadingAnchor, constant: -4),
            nameLabel.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            
            sexIcon.trailingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: -4),
            sexIcon.centerYAnchor.constraint(equalTo: playerHeaderView.centerYAnchor),
            sexIcon.widthAnchor.constraint(equalToConstant: 16),
            sexIcon.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        playerContainerView.addSubview(playerHeaderView)
        
        // NPC Container (RIGHT)
        npcContainerView.translatesAutoresizingMaskIntoConstraints = false
        npcContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        npcContainerView.layer.cornerRadius = 12
        view.addSubview(npcContainerView)
        
        // NPC Header - более информативный заголовок в стиле виджета
        npcHeaderView.translatesAutoresizingMaskIntoConstraints = false
        npcHeaderView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        npcHeaderView.layer.cornerRadius = 12
        
        // Настраиваем информацию о NPC
        let npcSexIcon = UIImageView(image: UIImage(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave"))
        npcSexIcon.tintColor = .white
        npcSexIcon.contentMode = .scaleAspectFit
        npcSexIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let npcNameLabel = UILabel()
        npcNameLabel.text = npc.name
        npcNameLabel.textColor = .white
        if let font = UIFont(name: "Optima", size: 12) {
            npcNameLabel.font = font
        }
        npcNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let npcProfessionIcon = UIImageView(image: UIImage(systemName: npc.profession.icon))
        // Преобразуем SwiftUI Color в UIColor
        if let color = UIColor(npc.profession.color) {
            npcProfessionIcon.tintColor = color
        } else {
            npcProfessionIcon.tintColor = .white
        }
        npcProfessionIcon.contentMode = .scaleAspectFit
        npcProfessionIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let npcCoinImageView = UIImageView(image: UIImage(systemName: "cedisign"))
        npcCoinImageView.tintColor = .green
        npcCoinImageView.translatesAutoresizingMaskIntoConstraints = false
        npcCoinImageView.contentMode = .scaleAspectFit
        
        let npcCoinsLabel = UILabel()
        npcCoinsLabel.text = "\(npc.coins.value)"
        npcCoinsLabel.textColor = .green
        if let font = UIFont(name: "Optima", size: 12) {
            npcCoinsLabel.font = font
        }
        npcCoinsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        npcHeaderView.addSubview(npcSexIcon)
        npcHeaderView.addSubview(npcNameLabel)
        npcHeaderView.addSubview(npcProfessionIcon)
        npcHeaderView.addSubview(npcCoinImageView)
        npcHeaderView.addSubview(npcCoinsLabel)
        
        // Устанавливаем констрейнты для элементов заголовка NPC
        NSLayoutConstraint.activate([
            npcSexIcon.leadingAnchor.constraint(equalTo: npcHeaderView.leadingAnchor, constant: 10),
            npcSexIcon.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            npcSexIcon.widthAnchor.constraint(equalToConstant: 16),
            npcSexIcon.heightAnchor.constraint(equalToConstant: 16),
            
            npcNameLabel.leadingAnchor.constraint(equalTo: npcSexIcon.trailingAnchor, constant: 4),
            npcNameLabel.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            
            npcProfessionIcon.leadingAnchor.constraint(equalTo: npcNameLabel.trailingAnchor, constant: 4),
            npcProfessionIcon.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            npcProfessionIcon.widthAnchor.constraint(equalToConstant: 16),
            npcProfessionIcon.heightAnchor.constraint(equalToConstant: 16),
            
            npcCoinsLabel.trailingAnchor.constraint(equalTo: npcHeaderView.trailingAnchor, constant: -10),
            npcCoinsLabel.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            
            npcCoinImageView.trailingAnchor.constraint(equalTo: npcCoinsLabel.leadingAnchor, constant: -4),
            npcCoinImageView.centerYAnchor.constraint(equalTo: npcHeaderView.centerYAnchor),
            npcCoinImageView.widthAnchor.constraint(equalToConstant: 14),
            npcCoinImageView.heightAnchor.constraint(equalToConstant: 14),
        ])
        
        npcContainerView.addSubview(npcHeaderView)
    }
    
    private func setupTableViews() {
        // NPC Items TableView
        npcItemsTableView.translatesAutoresizingMaskIntoConstraints = false
        npcItemsTableView.backgroundColor = .clear
        npcItemsTableView.separatorStyle = .none
        npcItemsTableView.register(ItemCell.self, forCellReuseIdentifier: "ItemCell")
        npcItemsTableView.dataSource = self
        npcItemsTableView.delegate = self
        npcItemsTableView.tag = 0 // Tag 0 for NPC items
        npcContainerView.addSubview(npcItemsTableView)
        
        // Player Items TableView
        playerItemsTableView.translatesAutoresizingMaskIntoConstraints = false
        playerItemsTableView.backgroundColor = .clear
        playerItemsTableView.separatorStyle = .none
        playerItemsTableView.register(ItemCell.self, forCellReuseIdentifier: "ItemCell")
        playerItemsTableView.dataSource = self
        playerItemsTableView.delegate = self
        playerItemsTableView.tag = 1 // Tag 1 for Player items
        playerContainerView.addSubview(playerItemsTableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Player Container (LEFT)
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playerContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            playerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            
            // Player Header View
            playerHeaderView.topAnchor.constraint(equalTo: playerContainerView.topAnchor, constant: 8),
            playerHeaderView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor, constant: 8),
            playerHeaderView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor, constant: -8),
            playerHeaderView.heightAnchor.constraint(equalToConstant: 30),
            
            // Player TableView
            playerItemsTableView.topAnchor.constraint(equalTo: playerHeaderView.bottomAnchor, constant: 8),
            playerItemsTableView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor, constant: 8),
            playerItemsTableView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor, constant: -8),
            playerItemsTableView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: -8),
            
            // NPC Container (RIGHT)
            npcContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            npcContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            npcContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            npcContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            
            // NPC Header View
            npcHeaderView.topAnchor.constraint(equalTo: npcContainerView.topAnchor, constant: 8),
            npcHeaderView.leadingAnchor.constraint(equalTo: npcContainerView.leadingAnchor, constant: 8),
            npcHeaderView.trailingAnchor.constraint(equalTo: npcContainerView.trailingAnchor, constant: -8),
            npcHeaderView.heightAnchor.constraint(equalToConstant: 30),
            
            // NPC TableView
            npcItemsTableView.topAnchor.constraint(equalTo: npcHeaderView.bottomAnchor, constant: 8),
            npcItemsTableView.leadingAnchor.constraint(equalTo: npcContainerView.leadingAnchor, constant: 8),
            npcItemsTableView.trailingAnchor.constraint(equalTo: npcContainerView.trailingAnchor, constant: -8),
            npcItemsTableView.bottomAnchor.constraint(equalTo: npcContainerView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupSwipeGesture() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        dismiss(animated: true)
    }
    
    // MARK: - Data Management
    private func updateItemGroups() {
        // Group NPC items
        let npcGroupedItems = Dictionary(grouping: npc.items, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
        self.npcItems = npcGroupedItems
        
        // Group Player items
        let playerGroupedItems = Dictionary(grouping: player.items, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
        self.playerItems = playerGroupedItems
        
        // Reload tables
        npcItemsTableView.reloadData()
        playerItemsTableView.reloadData()
    }
    
    private func moveItemFromNPCToPlayer(_ group: ItemGroup) {
        guard let item = group.items.first else { return }
        
        // Create a copy of the item and move it
        let newItem = Item.createUnique(item)
        player.items.append(newItem)
        
        // Remove the original item from NPC
        if let index = npc.items.firstIndex(where: { $0.index == item.index }) {
            npc.items.remove(at: index)
        }
        
        // Update UI
        updateItemGroups()
    }
    
    // Специальный метод для перевода монет от NPC к игроку
    private func transferCoinsFromNPCToPlayer() {
        if npc.coins.value > 0 {
            // Добавляем монеты к игроку
            player.coins.value += npc.coins.value
            
            // Обнуляем монеты у NPC
            npc.coins.value = 0
            
            // Обновляем отображение монет в заголовках
            if let npcCoinsLabel = npcHeaderView.subviews.compactMap({ $0 as? UILabel }).first(where: { $0.textColor == .green }) {
                npcCoinsLabel.text = "0"
            }
            
            if let playerCoinsLabel = playerHeaderView.subviews.compactMap({ $0 as? UILabel }).first(where: { $0.textColor == .green }) {
                playerCoinsLabel.text = "\(player.coins.value)"
            }
            
            // Обновляем UI
            updateItemGroups()
        }
    }
}

// MARK: - UITableViewDataSource
extension LootViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0 {
            // Для NPC: обычные предметы + специальная ячейка для монет (если они есть)
            return npcItems.count + (npc.coins.value > 0 ? 1 : 0)
        } else {
            return playerItems.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as? ItemCell else {
            return UITableViewCell()
        }
        
        if tableView.tag == 0 {
            // NPC items
            if indexPath.row < npcItems.count {
                // Обычный предмет
                let group = npcItems[indexPath.row]
                cell.configure(with: group)
            } else {
                // Специальная ячейка для монет
                cell.configureAsCoinItem(amount: npc.coins.value)
            }
        } else {
            // Player items
            let group = playerItems[indexPath.row]
            cell.configure(with: group)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LootViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Only allow taking items from NPC
        if tableView.tag == 0 {
            if indexPath.row < npcItems.count {
                // Обычный предмет
                let group = npcItems[indexPath.row]
                moveItemFromNPCToPlayer(group)
            } else {
                // Специальная ячейка для монет
                transferCoinsFromNPCToPlayer()
            }
        }
    }
}

// MARK: - Item Cell
class ItemCell: UITableViewCell {
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
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        containerView.layer.cornerRadius = 8
        contentView.addSubview(containerView)
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .center
        containerView.addSubview(iconImageView)
        
        // Name label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        if let font = UIFont(name: "Optima", size: 12) {
            nameLabel.font = font
        }
        containerView.addSubview(nameLabel)
        
        // Cost label
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        costLabel.textColor = UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
        if let font = UIFont(name: "Optima", size: 12) {
            costLabel.font = font
        }
        costLabel.textAlignment = .right
        containerView.addSubview(costLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 26),
            iconImageView.heightAnchor.constraint(equalToConstant: 26),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            costLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            costLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            costLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 12)
        ])
    }
    
    func configure(with group: ItemGroup) {
        // Set icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
        iconImageView.image = UIImage(systemName: group.icon, withConfiguration: iconConfig)
        
        // Set icon color
        if let color = UIColor(group.color) {
            iconImageView.tintColor = color
        } else {
            iconImageView.tintColor = .white
        }
        
        // Set name with count if needed
        nameLabel.text = group.count > 1 ? "\(group.name) (\(group.count))" : group.name
        
        // Set cost
        costLabel.text = "\(group.cost)"
    }
    
    // Отдельный метод для конфигурации ячейки как элемента Coins
    func configureAsCoinItem(amount: Int) {
        // Устанавливаем иконку монет
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14)
        iconImageView.image = UIImage(systemName: "cedisign.circle.fill", withConfiguration: iconConfig)
        iconImageView.tintColor = .green
        
        // Устанавливаем название
        nameLabel.text = "Coins"
        nameLabel.textColor = .white
        
        // Устанавливаем количество
        costLabel.text = "\(amount)"
        costLabel.textColor = UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        nameLabel.text = nil
        costLabel.text = nil
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init?(_ color: Color) {
        let components = color.cgColor?.components
        guard let components = components, components.count >= 3 else {
            return nil
        }
        
        self.init(red: CGFloat(components[0]),
                  green: CGFloat(components[1]),
                  blue: CGFloat(components[2]),
                  alpha: components.count >= 4 ? CGFloat(components[3]) : 1.0)
    }
}

// MARK: - SwiftUI Representable
struct LootView: UIViewControllerRepresentable {
    let player: Player
    let npc: NPC
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    
    func makeUIViewController(context: Context) -> LootViewController {
        let viewController = LootViewController(player: player, npc: npc, scene: scene, mainViewModel: mainViewModel)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: LootViewController, context: Context) {
        // Updates if needed
    }
} 
