import UIKit
import SwiftUI

class CombatViewController: UIViewController {
    private let mainViewModel: MainSceneViewModel
    private var npcManager: NPCInteractionManager = NPCInteractionManager.shared
    private var npc: NPC
    private var npcAssistants: [NPC] = []
    
    // UI
    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let universalPlayerCell = UniversalCharacterCell(frame: CGRect(x: 0, y: 0, width: 110, height: 110))
    private let universalNpcCell = UniversalCharacterCell(frame: CGRect(x: 0, y: 0, width: 110, height: 110))
    private let vsLabel = UILabel()
    // Новый стек для кнопок действий
    private let actionsButtonsStack = UIStackView()
    private let resultLabel = UILabel()
    private let finishButton = UIButton(type: .system)
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    // Кнопки после завершения боя
    private let witnessWarningLabel = UILabel()
    private let combatLogImageView = UIImageView()
    private let centerWidgetsContainer = UIView()
    private let combatLogContainer = UIView()
    private let combatLogScrollView = UIScrollView()
    private let combatLogStackView = UIStackView()
    private let playerNameLabel = UILabel()
    private let npcNameLabel = UILabel()
    // Overlay and widget references
    private var widgetOverlayView: UIView?
    private var playerWidgetVC: PlayerWidgetUIViewController?
    private var npcWidgetVC: NPCWidgetUIViewController?
    // --- Assistants UI ---
    private var assistantNpcCells: [UniversalCharacterCellSmall] = []
    private let npcDeckContainer = UIView()
    // --- Новый стек для игрока и кнопок ---
    private let playerAndActionsStack = UIStackView()
    // --- Новый стек для главного NPC ---
    private let npcAndActionsStack = UIStackView()
    
    // State
    private var player: Player? { GameStateService.shared.player }
    private var lastActionType: CombatActionType? = nil
    private var isCombatEnded: Bool = false
    private var didLoadAssistants = false
    private var previousAliveEnemiesCount: Int = 0
    
    // Player state tracking to avoid unnecessary redraws
    // The player widget should only be redrawn when the player's health or alive state changes
    private var lastPlayerHealth: Float = 0
    private var lastPlayerAliveState: Bool = true
    
    // Callbacks для навигации
    var onLeave: (() -> Void)? = nil
    var onLoot: (() -> Void)? = nil
    
    init(mainViewModel: MainSceneViewModel, npc: NPC) {
        self.mainViewModel = mainViewModel
        self.npc = npc
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNpcAssitants()
        setupBackgroundImage()
        setupTopWidget()
        setupCombatUI()
        setupInitialCombatState()
        setupActionButtons()
        setupDoubleTapGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let extraSpace: CGFloat = 100
        let viewport = view.bounds
        let expandedFrame = CGRect(
            x: -extraSpace/2,
            y: -extraSpace/2,
            width: viewport.width + extraSpace,
            height: viewport.height + extraSpace
        )
        backgroundImageView.frame = expandedFrame
        dustEffectView?.view.frame = viewport
        view.sendSubviewToBack(backgroundImageView)
        if let dustView = dustEffectView?.view {
            view.insertSubview(dustView, aboveSubview: backgroundImageView)
        }
        // --- Layout assistants after all frames are set ---
        layoutAssistantNPCs()
    }
    
    private func loadNpcAssitants() {
        npcAssistants = GameStateService.shared.getNPCAssistants(npc: self.npc)
    }
    
    private func setupCombatUI() {
        // --- 1 СТОЛБЕЦ: Игрок и кнопки действий ---
        playerAndActionsStack.axis = .vertical
        playerAndActionsStack.alignment = .leading
        playerAndActionsStack.spacing = 16
        playerAndActionsStack.translatesAutoresizingMaskIntoConstraints = false
        playerAndActionsStack.arrangedSubviews.forEach { playerAndActionsStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        
        universalPlayerCell.translatesAutoresizingMaskIntoConstraints = false
        actionsButtonsStack.axis = .vertical
        actionsButtonsStack.alignment = .leading
        actionsButtonsStack.spacing = 12
        actionsButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsButtonsStack.arrangedSubviews.forEach { actionsButtonsStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        
        let actionsButtonsContainer = UIView()
        actionsButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        actionsButtonsContainer.addSubview(actionsButtonsStack)
        NSLayoutConstraint.activate([
            actionsButtonsStack.topAnchor.constraint(equalTo: actionsButtonsContainer.topAnchor, constant: 16),
            actionsButtonsStack.leadingAnchor.constraint(equalTo: actionsButtonsContainer.leadingAnchor),
            actionsButtonsStack.trailingAnchor.constraint(equalTo: actionsButtonsContainer.trailingAnchor),
            actionsButtonsStack.bottomAnchor.constraint(equalTo: actionsButtonsContainer.bottomAnchor)
        ])
        
        playerAndActionsStack.addArrangedSubview(universalPlayerCell)
        playerAndActionsStack.addArrangedSubview(actionsButtonsContainer)
        view.addSubview(playerAndActionsStack)
        
        // Лейбл имени игрока
        playerNameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        playerNameLabel.textColor = .white
        playerNameLabel.textAlignment = .center
        playerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        playerNameLabel.layer.shadowColor = UIColor.black.cgColor
        playerNameLabel.layer.shadowOpacity = 0.7
        playerNameLabel.layer.shadowRadius = 3
        playerNameLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(playerNameLabel)

        // --- 2 СТОЛБЕЦ: Центральный контейнер (временно без ассета) ---
        combatLogContainer.translatesAutoresizingMaskIntoConstraints = false
        combatLogContainer.clipsToBounds = false
        combatLogContainer.layer.cornerRadius = 8
        combatLogContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        combatLogContainer.layer.shadowColor = UIColor.black.cgColor
        combatLogContainer.layer.shadowOpacity = 0.6
        combatLogContainer.layer.shadowRadius = 8
        combatLogContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.addSubview(combatLogContainer)
        
        // Временно убираем ассет - используем простой фон
        // combatLogImageView код закомментирован
        
        // Предупреждение о свидетелях
        witnessWarningLabel.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        witnessWarningLabel.textColor = UIColor.systemRed
        witnessWarningLabel.textAlignment = .center
        witnessWarningLabel.numberOfLines = 2
        witnessWarningLabel.layer.shadowColor = UIColor.black.cgColor
        witnessWarningLabel.layer.shadowOpacity = 0.7
        witnessWarningLabel.layer.shadowRadius = 3
        witnessWarningLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        witnessWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(witnessWarningLabel)

        // VS label убран
        
        // Combat log scroll view
        combatLogScrollView.translatesAutoresizingMaskIntoConstraints = false
        combatLogScrollView.showsVerticalScrollIndicator = true
        combatLogScrollView.showsHorizontalScrollIndicator = false
        combatLogScrollView.backgroundColor = .clear
        combatLogScrollView.contentInsetAdjustmentBehavior = .never
        combatLogContainer.addSubview(combatLogScrollView)
        
        // Combat log stack view для истории сообщений
        combatLogStackView.axis = .vertical
        combatLogStackView.alignment = .fill
        combatLogStackView.distribution = .fill
        combatLogStackView.spacing = 8
        combatLogStackView.translatesAutoresizingMaskIntoConstraints = false
        combatLogScrollView.addSubview(combatLogStackView)

        // --- 3 СТОЛБЕЦ: NPC и ассистенты ---
        npcAndActionsStack.axis = .vertical
        npcAndActionsStack.alignment = .trailing
        npcAndActionsStack.spacing = 16
        npcAndActionsStack.translatesAutoresizingMaskIntoConstraints = false
        npcAndActionsStack.arrangedSubviews.forEach { npcAndActionsStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        
        universalNpcCell.translatesAutoresizingMaskIntoConstraints = false
        npcAndActionsStack.addArrangedSubview(universalNpcCell)
        view.addSubview(npcAndActionsStack)
        
        // Лейбл имени NPC
        npcNameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        npcNameLabel.textColor = .white
        npcNameLabel.textAlignment = .center
        npcNameLabel.translatesAutoresizingMaskIntoConstraints = false
        npcNameLabel.layer.shadowColor = UIColor.black.cgColor
        npcNameLabel.layer.shadowOpacity = 0.7
        npcNameLabel.layer.shadowRadius = 3
        npcNameLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(npcNameLabel)
        
        // Контейнер ассистентов
        npcDeckContainer.translatesAutoresizingMaskIntoConstraints = false
        npcDeckContainer.clipsToBounds = false
        view.addSubview(npcDeckContainer)

        // Старый resultLabel теперь не нужен, используем combatLogTextLabel
        resultLabel.removeFromSuperview()

        // Layout
        NSLayoutConstraint.activate([
            // 1 столбец - игрок и кнопки
            playerAndActionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playerAndActionsStack.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 40),
            universalPlayerCell.widthAnchor.constraint(equalToConstant: 110),
            universalPlayerCell.heightAnchor.constraint(equalToConstant: 110),
            
            // Имя игрока над виджетом
            playerNameLabel.bottomAnchor.constraint(equalTo: playerAndActionsStack.topAnchor, constant: -8),
            playerNameLabel.centerXAnchor.constraint(equalTo: universalPlayerCell.centerXAnchor),
            
            // Combat log container - фиксированный размер внизу экрана
            combatLogContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            combatLogContainer.widthAnchor.constraint(equalToConstant: 350),
            combatLogContainer.heightAnchor.constraint(equalToConstant: 150),
            combatLogContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Фон контейнера - временно убран
            
            // Witness warning label - в верхней части центральной колонки
            witnessWarningLabel.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 16),
            witnessWarningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            witnessWarningLabel.leadingAnchor.constraint(greaterThanOrEqualTo: playerAndActionsStack.trailingAnchor, constant: 16),
            witnessWarningLabel.trailingAnchor.constraint(lessThanOrEqualTo: npcAndActionsStack.leadingAnchor, constant: -16),
            
            // Combat log scroll view constraints - заполняет весь контейнер
            combatLogScrollView.topAnchor.constraint(equalTo: combatLogContainer.topAnchor, constant: 8),
            combatLogScrollView.leadingAnchor.constraint(equalTo: combatLogContainer.leadingAnchor, constant: 8),
            combatLogScrollView.trailingAnchor.constraint(equalTo: combatLogContainer.trailingAnchor, constant: -8),
            combatLogScrollView.bottomAnchor.constraint(equalTo: combatLogContainer.bottomAnchor, constant: -8),
            
            // Combat log stack view constraints
            combatLogStackView.topAnchor.constraint(equalTo: combatLogScrollView.topAnchor),
            combatLogStackView.leadingAnchor.constraint(equalTo: combatLogScrollView.leadingAnchor),
            combatLogStackView.trailingAnchor.constraint(equalTo: combatLogScrollView.trailingAnchor),
            combatLogStackView.bottomAnchor.constraint(equalTo: combatLogScrollView.bottomAnchor),
            combatLogStackView.widthAnchor.constraint(equalTo: combatLogScrollView.widthAnchor),
            
            // 3 столбец - NPC и ассистенты
            npcAndActionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            npcAndActionsStack.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 40),
            universalNpcCell.widthAnchor.constraint(equalToConstant: 110),
            universalNpcCell.heightAnchor.constraint(equalToConstant: 110),
            
            // Имя NPC над виджетом
            npcNameLabel.bottomAnchor.constraint(equalTo: npcAndActionsStack.topAnchor, constant: -8),
            npcNameLabel.centerXAnchor.constraint(equalTo: universalNpcCell.centerXAnchor),
            
            // Контейнер ассистентов под NPC
            npcDeckContainer.centerXAnchor.constraint(equalTo: universalNpcCell.centerXAnchor),
            npcDeckContainer.topAnchor.constraint(equalTo: universalNpcCell.bottomAnchor, constant: 4),
            npcDeckContainer.widthAnchor.constraint(equalToConstant: 125),
            npcDeckContainer.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func setupInitialCombatState() {
        guard let player = player else { return }
        
        // Используем новую групповую боевую систему
        CombatService.shared.startGroupCombat(player: player, primaryNpc: npc, assistants: npcAssistants)
        
        // Инициализируем отслеживание состояния игрока
        lastPlayerHealth = player.bloodMeter.currentBlood
        lastPlayerAliveState = player.isAlive
        
        universalPlayerCell.configure(with: player, isDisabled: false)
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        
        // Устанавливаем имена
        playerNameLabel.text = player.name
        npcNameLabel.text = npc.name
        
        // Обновляем информацию о групповом бое
        updateGroupCombatInfo()
        
        // Инициализируем combat log
        initializeCombatLog()
        
        // Устанавливаем начальное количество врагов
        let status = CombatService.shared.getGroupCombatStatus()
        previousAliveEnemiesCount = status.aliveEnemies
        
        // --- Assistants setup ---
        setupAssistantNPCs()
        checkCombatEnd()
    }
    
    private func setupAssistantNPCs() {
        // Удаляем все старые карточки из npcDeckContainer
        for view in npcDeckContainer.subviews { view.removeFromSuperview() }
        assistantNpcCells.removeAll()
        
        // Получаем всех ассистентов без лимитов
        let assistants = npcAssistants
        let cellSize: CGFloat = 55 // Уменьшаем размер с 65 до 55
        
        // Создаем карточки для всех ассистентов
        for (i, assistant) in assistants.enumerated() {
            let cell = UniversalCharacterCellSmall(frame: CGRect(x: 0, y: 0, width: cellSize, height: cellSize))
            cell.configure(with: assistant, isSelected: false, isDisabled: false)
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.clipsToBounds = false
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleAssistantTap(_:)))
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            cell.tag = i
            
            npcDeckContainer.addSubview(cell)
            assistantNpcCells.append(cell)
        }
    }
    
    @objc private func handleAssistantTap(_ sender: UITapGestureRecognizer) {
        guard let tappedCell = sender.view as? UniversalCharacterCellSmall,
              let index = assistantNpcCells.firstIndex(of: tappedCell) else { return }
        guard index < npcAssistants.count else { return }
        
        print("Assistant tap: index \(index), total assistants: \(npcAssistants.count)")
        
        let selectedAssistant = npcAssistants[index]
        let oldMainNpc = self.npc
        
        // Выбранный ассистент становится главным NPC
        self.npc = selectedAssistant
        self.npcManager.selectedNPC = selectedAssistant
        
        // Удаляем выбранного ассистента из коллекции
        self.npcAssistants.remove(at: index)
        
        // Добавляем предыдущего главного NPC в коллекцию ассистентов
        self.npcAssistants.append(oldMainNpc)
        
        // Пересоздаем UI ассистентов с новой коллекцией
        setupAssistantNPCs()
        layoutAssistantNPCs()
        
        // Обновляем главную ячейку
        universalNpcCell.configure(with: self.npc, isSelected: true, isDisabled: false)
        
        // Обновляем имя NPC
        npcNameLabel.text = self.npc.name
        
        // Добавляем сообщение о смене цели в лог
        addCombatLogMessage("🎯 Your gaze turns to \(self.npc.name)", color: .systemYellow, isSystemMessage: true)
        
        setupActionButtons()
        
        // Обновляем UI без добавления результата действия
        // Игрок не изменился при смене цели, поэтому не перерисовываем его виджет
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        
        // Обновляем информацию о групповом бое
        updateGroupCombatInfo()
        
        // --- Обновляем ассистентов ---
        setupAssistantNPCs()
        checkCombatEnd()
    }
    
    private func activateNPC(_ selectedNPC: NPC) {
        // Сохраняем предыдущего NPC
        let previousNPC = self.npc
        
        // Обновляем текущего NPC
        self.npc = selectedNPC
        self.npcManager.selectedNPC = selectedNPC
        
        // Получаем текущий список ассистентов для нового NPC (исключая его самого)
        var newAssistants = GameStateService.shared.getNPCAssistants(npc: selectedNPC)
            .filter { $0.id != selectedNPC.id }
        
        // Добавляем предыдущего NPC в ассистенты, если его еще нет
        if !newAssistants.contains(where: { $0.id == previousNPC.id }) {
            newAssistants.insert(previousNPC, at: 0)
        }
        
        // Обновляем массив ассистентов
        self.npcAssistants = newAssistants
        
        // Обновляем главную ячейку
        universalNpcCell.configure(with: selectedNPC, isSelected: true, isDisabled: false)
        
        // Обновляем ячейки ассистентов
        for (i, cell) in assistantNpcCells.enumerated() {
            if i < npcAssistants.count {
                cell.configure(with: npcAssistants[i], isSelected: false, isDisabled: false)
            } else {
                cell.isHidden = true
            }
        }
        
        // Обновляем layout
        layoutAssistantNPCs()
        
        // Обновляем UI
        setupActionButtons()
        // Не вызываем updateUIAfterAction() так как это смена цели, а не боевое действие
        // Обновляем только NPC виджет и ассистентов
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        updateGroupCombatInfo()
        setupAssistantNPCs()
        checkCombatEnd()
    }
    
    private func layoutAssistantNPCs() {
        let cellSize: CGFloat = 55 // Уменьшаем размер с 65 до 55
        let spacing: CGFloat = 12 // Увеличиваем вертикальное расстояние с 8 до 12
        let columnSpacing: CGFloat = 15 // Увеличиваем горизонтальное расстояние с 10 до 15
        
        // Размещаем ассистентов в 2 вертикальные колонки (сначала правая, потом левая)
        for (i, cell) in assistantNpcCells.enumerated() {
            let column = 1 - (i % 2) // 1 для правой колонки, 0 для левой (инвертируем)
            let row = i / 2 // Номер строки в колонке
            
            let x = CGFloat(column) * (cellSize + columnSpacing)
            let y = CGFloat(row) * (cellSize + spacing)
            
            cell.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
        }
    }
    
    private func setupActionButtons() {
        actionsButtonsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if isCombatEnded {
            if npc.isAlive == false {
                let lootButton = ActionButtonSmallView(title: "Loot", icon: "bag.fill", color: .systemYellow) { [weak self] in
                    self?.openLoot()
                }
                actionsButtonsStack.addArrangedSubview(lootButton)
            }
            let leaveButton = ActionButtonSmallView(title: "Leave", icon: "arrowshape.turn.up.left.fill", color: .white) { [weak self] in
                self?.closeCombat()
            }
            actionsButtonsStack.addArrangedSubview(leaveButton)
            return
        }
        
        var actions: [(title: String, icon: String, color: UIColor, handler: () -> Void)] = [
            ("Attack", "flame", .systemOrange, { [weak self] in
                guard let self = self else { return }
                self.lastActionType = .attack
                // Используем текущего NPC!
                let action = CombatAction(
                    type: .attack,
                    initiatorId: "",
                    target: self.npc,
                    parameters: nil
                )
                CombatService.shared.performGroupAction(action)
                self.updateUIAfterAction()
            }),
            ("Bite", "mouth.fill", .systemPink, { [weak self] in
                guard let self = self else { return }
                self.lastActionType = .feed
                let action = CombatAction(
                    type: .feed,
                    initiatorId: "",
                    target: self.npc,
                    parameters: nil
                )
                CombatService.shared.performGroupAction(action)
                self.updateUIAfterAction()
            }),
            ("Drain", "drop.triangle.fill", .systemRed, { [weak self] in
                guard let self = self else { return }
                self.lastActionType = .drain
                let action = CombatAction(
                    type: .drain,
                    initiatorId: "",
                    target: self.npc,
                    parameters: nil
                )
                CombatService.shared.performGroupAction(action)
                self.updateUIAfterAction()
            }),
        ]

        if AbilitiesSystem.shared.hasDomination {
            actions.insert(
                ("Dominate", "eye", .systemBlue, { [weak self] in
                guard let self = self else { return }
                self.lastActionType = .dominate
                let action = CombatAction(
                    type: .dominate,
                    initiatorId: "",
                    target: self.npc,
                    parameters: nil
                )
                CombatService.shared.performGroupAction(action)
                self.updateUIAfterAction()
                }), at: 2)
        }
        // Witness warning label всегда показывается в центральной колонке
        let witnesses = GameStateService.shared.getWitnessesCount()
        let hasVampireAction = actions.contains(where: { $0.title == "Bite" || $0.title == "Drain" || $0.title == "Dominate" })
        
        if witnesses > 0 && hasVampireAction {
            witnessWarningLabel.text = "⚠️ Prying eyes watch from shadows... (\(witnesses) souls)"
            witnessWarningLabel.textColor = UIColor.systemRed
        } else if hasVampireAction {
            witnessWarningLabel.text = "🌑 Darkness conceals your unholy hunger..."
            witnessWarningLabel.textColor = UIColor.systemGreen
        } else if witnesses > 0 {
            witnessWarningLabel.text = "⚠️ \(witnesses) onlookers witness this bloodshed"
            witnessWarningLabel.textColor = UIColor.systemYellow
        } else {
            witnessWarningLabel.text = "⚔️ Steel rings against steel"
            witnessWarningLabel.textColor = UIColor.systemBlue
        }
        witnessWarningLabel.isHidden = false
        for (title, icon, color, handler) in actions {
            // Получаем шанс успеха с учетом групповой механики
            let actionType: CombatActionType = {
                switch title {
                case "Attack": return .attack
                case "Bite": return .feed
                case "Drain": return .drain
                case "Dominate": return .dominate
                default: return .attack
                }
            }()
            
            let status = CombatService.shared.getGroupCombatStatus()
            let chance = CombatService.shared.getGroupCombatChance(for: actionType, enemyCount: status.aliveEnemies)
            let chancePercent = Int(chance * 100)
            
            // Цветовая индикация сложности боя
            let difficultyColor = getDifficultyColor(for: chance, enemyCount: status.aliveEnemies)
            let button = ActionButtonSmallView(title: title, icon: icon, color: difficultyColor, onTap: handler)
            button.setSubtitle("\(chancePercent)%")
            
            // --- Делаем кнопку неактивной, если NPC мертв ---
            button.isEnabled = npc.isAlive
            button.alpha = npc.isAlive ? 1.0 : 0.7
            actionsButtonsStack.addArrangedSubview(button)
        }
    }
    
    // Маппинг последствий на текст, цвет и иконку для игрока
    private func prettyCombatResultText(_ summary: String) -> (NSAttributedString, UIColor) {
        let lower = summary.lowercased()
        let isSuccess = lower.contains("success")
        
        var text = ""
        var color = UIColor.white
        var icon = ""
        
        // Обрабатываем новые групповые сообщения
        if summary.contains("overwhelmed by") {
            let parts = summary.components(separatedBy: " ")
            if let enemyCountStr = parts.first(where: { $0.contains("enemies") })?.replacingOccurrences(of: "enemies", with: "").trimmingCharacters(in: .whitespaces),
               let enemyCount = Int(enemyCountStr) {
                text = "⚔️ Surrounded and beaten by \(enemyCount) foes!"
            } else {
                text = "⚔️ " + summary
            }
            color = UIColor.systemRed
            icon = ""
        } else if summary.contains("feeding interrupted by") {
            text = "🗡️ " + summary.replacingOccurrences(of: "Fail: ", with: "").replacingOccurrences(of: "feeding interrupted by", with: "Blood feast interrupted by")
            color = UIColor.systemOrange
            icon = ""
        } else if summary.contains("all") && summary.contains("enemies attack") {
            text = "💀 " + summary.replacingOccurrences(of: "Fail: ", with: "").replacingOccurrences(of: "all", with: "All").replacingOccurrences(of: "enemies attack", with: "foes strike in unison")
            color = UIColor.systemRed
            icon = ""
        } else if summary.contains("dominated (temporarily out of combat)") {
            text = "👁️ " + summary.replacingOccurrences(of: "Success: ", with: "").replacingOccurrences(of: "dominated (temporarily out of combat)", with: "mind enslaved, cowering in terror")
            color = UIColor.systemBlue
            icon = ""
        } else if summary.contains("fed on") {
            text = "🩸 " + summary.replacingOccurrences(of: "Success: ", with: "").replacingOccurrences(of: "fed on", with: "Drained the life essence from")
            color = UIColor.systemPink
            icon = ""
        } else if summary.contains("drained") && summary.contains("completely") {
            text = "💀 " + summary.replacingOccurrences(of: "Success: ", with: "").replacingOccurrences(of: "drained", with: "Consumed the very soul of").replacingOccurrences(of: "completely", with: "- nothing remains")
            color = UIColor.systemRed
            icon = ""
        } else {
            // Обрабатываем стандартные сообщения
            let code: String = {
                if let idx = lower.firstIndex(of: ":") {
                    return lower[lower.index(after: idx)...].trimmingCharacters(in: .whitespaces)
                }
                return lower
            }()
            
            switch code {
            case let s where s.contains("damage_caused"):
                if isSuccess {
                    // Извлекаем информацию об уроне из summary
                    let damageInfo = extractDamageInfo(from: summary)
                    let targetName = extractTargetName(from: summary) ?? self.npc.name
                    text = "⚔️ Your blade finds flesh - \(targetName) bleeds\(damageInfo)"
                    color = UIColor.systemGreen
                } else {
                    text = "🛡️ Your strike falters - \(self.npc.name) retaliates!"
                    color = UIColor.systemRed
                }
            case let s where s.contains("player_damaged"):
                if isSuccess {
                    text = "🩸 Crimson vitality flows through you!"
                    color = UIColor.systemPink
                } else {
                    let damageInfo = extractDamageInfo(from: summary)
                    text = "🗡️ Steel bites deep into your flesh\(damageInfo)"
                    color = UIColor.systemRed
                }
            case let s where s.contains("target_bited"):
                let healInfo = extractHealInfo(from: summary)
                text = "🩸 Fangs pierce flesh - warm blood sustains you\(healInfo)"
                color = UIColor.systemPink
            case let s where s.contains("npc_dominated"):
                text = "👁️ \(self.npc.name)'s will crumbles before your gaze!"
                color = UIColor.systemBlue
            case let s where s.contains("no_effect"):
                text = "— Your efforts prove futile."
                color = UIColor.systemGray
            case let s where s.contains("target_drained"):
                text = "💀 \(self.npc.name)'s life essence flows into the void!"
                color = UIColor.systemRed
            default:
                text = summary
                color = UIColor.white
            }
        }
        
        let pretty = NSMutableAttributedString(string: text)
        pretty.addAttribute(.font, value: UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: pretty.length))
        pretty.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: pretty.length))
        return (pretty, color)
    }
    
    // MARK: - Helper Methods for Damage Extraction
    
    private func extractDamageInfo(from summary: String) -> String {
        // Ищем паттерн (-XX HP) в строке
        let pattern = "\\(-\\d+ HP\\)"
        if let range = summary.range(of: pattern, options: .regularExpression) {
            return " " + String(summary[range])
        }
        return ""
    }
    
    private func extractTargetName(from summary: String) -> String? {
        // Ищем имя цели в скобках перед информацией об уроне
        // Паттерн: (Name) (-XX HP)
        let pattern = "\\(([^)]+)\\) \\(-\\d+ HP\\)"
        if let range = summary.range(of: pattern, options: .regularExpression) {
            let match = String(summary[range])
            // Извлекаем имя из первых скобок
            if let nameRange = match.range(of: "\\(([^)]+)\\)", options: .regularExpression) {
                let nameMatch = String(match[nameRange])
                // Убираем скобки
                return String(nameMatch.dropFirst().dropLast())
            }
        }
        return nil
    }
    
    private func extractHealInfo(from summary: String) -> String {
        // Ищем паттерн (+XX HP) в строке
        let pattern = "\\(\\+\\d+ HP\\)"
        if let range = summary.range(of: pattern, options: .regularExpression) {
            return " " + String(summary[range])
        }
        return ""
    }
    
    private func hasPlayerStateChanged() -> Bool {
        guard let player = player else { return false }
        
        let currentHealth = player.bloodMeter.currentBlood
        let currentAliveState = player.isAlive
        
        let hasChanged = currentHealth != lastPlayerHealth || currentAliveState != lastPlayerAliveState
        
        if hasChanged {
            lastPlayerHealth = currentHealth
            lastPlayerAliveState = currentAliveState
        }
        
        return hasChanged
    }
    
    private func updateUIAfterAction() {
        // Добавляем результат действия в лог
        if let summary = CombatService.shared.resultSummary {
            let (pretty, _) = prettyCombatResultText(summary)
            addCombatLogAttributedMessage(pretty)
        }
        
        // Оптимизированное обновление игрока - только здоровье если изменилось
        if let player = player {
            let currentHealth = player.bloodMeter.currentBlood
            let currentAliveState = player.isAlive
            
            if currentHealth != lastPlayerHealth || currentAliveState != lastPlayerAliveState {
                // Используем оптимизированный метод обновления только здоровья
                universalPlayerCell.updatePlayerHealth(player)
                lastPlayerHealth = currentHealth
                lastPlayerAliveState = currentAliveState
            }
        }
        
        // NPC всегда обновляем полностью, так как может измениться цель
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        
        // Обновляем информацию о групповом бое
        updateGroupCombatInfo()
        
        // Добавляем информацию о состоянии боя
        updateCombatStatusInLog()
        
        // --- Обновляем ассистентов ---
        setupAssistantNPCs()
        checkCombatEnd()
        setupActionButtons()
    }
    
    private func updateGroupCombatInfo() {
        // Эта функция больше не обновляет witness warning label
        // Witness warning label обновляется только в setupActionButtons()
        // Здесь можно добавить другую логику обновления UI если нужно
    }
    
    private func getDifficultyColor(for chance: Double, enemyCount: Int) -> UIColor {
        // Базовая цветовая схема в зависимости от шансов успеха
        let baseColor: UIColor
        if chance >= 0.7 {
            baseColor = UIColor.systemGreen      // Высокие шансы - зеленый
        } else if chance >= 0.5 {
            baseColor = UIColor.systemYellow     // Средние шансы - желтый  
        } else if chance >= 0.3 {
            baseColor = UIColor.systemOrange     // Низкие шансы - оранжевый
        } else {
            baseColor = UIColor.systemRed        // Очень низкие шансы - красный
        }
        
        // Дополнительная индикация для множественных врагов
        if enemyCount >= 4 {
            // При 4+ врагах делаем цвет более насыщенным/темным
            return baseColor.withAlphaComponent(0.9)
        } else if enemyCount >= 3 {
            // При 3 врагах немного затемняем
            return baseColor.withAlphaComponent(0.8)
        } else {
            // 1-2 врага - обычный цвет
            return baseColor
        }
    }
    
    private func updateCombatStatusInLog() {
        let status = CombatService.shared.getGroupCombatStatus()
        
        // Добавляем информацию о состоянии боя только если было действие (есть resultSummary)
        guard CombatService.shared.resultSummary != nil else { return }
        
        // Проверяем, изменилось ли количество живых врагов
        if status.aliveEnemies < previousAliveEnemiesCount {
            let killedCount = previousAliveEnemiesCount - status.aliveEnemies
            
            if status.aliveEnemies > 1 {
                let statusMessage = "💀 \(killedCount) \(killedCount > 1 ? "souls" : "soul") claimed, \(status.aliveEnemies) still draw breath"
                addCombatLogMessage(statusMessage, color: .systemGray2, isSystemMessage: true)
            } else if status.aliveEnemies == 1 {
                let statusMessage = "💀 \(killedCount) \(killedCount > 1 ? "have" : "has") fallen, one foe remains"
                addCombatLogMessage(statusMessage, color: .systemGray2, isSystemMessage: true)
            }
            
            // Обновляем счетчик
            previousAliveEnemiesCount = status.aliveEnemies
        }
    }
    
    private func getDifficultyLevel(for chance: Double, enemyCount: Int) -> String {
        let baseLevel: String
        if chance >= 0.7 {
            baseLevel = "Easy"
        } else if chance >= 0.5 {
            baseLevel = "Medium"
        } else if chance >= 0.3 {
            baseLevel = "Hard"
        } else {
            baseLevel = "Extreme"
        }
        
        // Добавляем модификатор для множественных врагов
        if enemyCount >= 4 {
            return "\(baseLevel) (Overwhelming)"
        } else if enemyCount >= 3 {
            return "\(baseLevel) (Outnumbered)"
        } else {
            return baseLevel
        }
    }
    
    // MARK: - Combat Log Methods
    
    private func initializeCombatLog() {
        // Очищаем предыдущие сообщения
        combatLogStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Добавляем начальное сообщение
        let status = CombatService.shared.getGroupCombatStatus()
        let initialMessage: String
        
        if status.totalEnemies > 1 {
            initialMessage = "⚔️ Battle erupts - \(status.totalEnemies) foes stand against you!"
        } else {
            initialMessage = "⚔️ Steel meets steel - \(npc.name) draws blade!"
        }
        
        addCombatLogMessage(initialMessage, color: .systemBlue, isSystemMessage: true)
        
        // Показываем сложность боя если это групповой бой
        if status.aliveEnemies > 1 {
            let attackChance = CombatService.shared.getGroupCombatChance(for: .attack, enemyCount: status.aliveEnemies)
            let difficultyLevel = getDifficultyLevel(for: attackChance, enemyCount: status.aliveEnemies)
            let difficultyColor = getDifficultyColor(for: attackChance, enemyCount: status.aliveEnemies)
            
            addCombatLogMessage("The odds weigh heavy: \(difficultyLevel)", color: difficultyColor, isSystemMessage: true)
        }
    }
    
    private func addCombatLogMessage(_ text: String, color: UIColor = .white, isSystemMessage: Bool = false) {
        let messageLabel = UILabel()
        messageLabel.font = UIFont(name: "Optima-Regular", size: isSystemMessage ? 13 : 14) ?? UIFont.systemFont(ofSize: isSystemMessage ? 13 : 14)
        messageLabel.textColor = color
        messageLabel.textAlignment = isSystemMessage ? .center : .left
        messageLabel.numberOfLines = 0
        messageLabel.text = text
        
        // Добавляем тень для лучшей читаемости
        messageLabel.layer.shadowColor = UIColor.black.cgColor
        messageLabel.layer.shadowOpacity = 0.7
        messageLabel.layer.shadowRadius = 2
        messageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Добавляем отступы для системных сообщений
        if isSystemMessage {
            messageLabel.alpha = 0.8
        }
        
        combatLogStackView.addArrangedSubview(messageLabel)
        
        // Автоматически прокручиваем вниз
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    private func addCombatLogAttributedMessage(_ attributedText: NSAttributedString) {
        let messageLabel = UILabel()
        messageLabel.attributedText = attributedText
        messageLabel.textAlignment = .left
        messageLabel.numberOfLines = 0
        
        // Добавляем тень для лучшей читаемости
        messageLabel.layer.shadowColor = UIColor.black.cgColor
        messageLabel.layer.shadowOpacity = 0.7
        messageLabel.layer.shadowRadius = 2
        messageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        combatLogStackView.addArrangedSubview(messageLabel)
        
        // Автоматически прокручиваем вниз
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        let contentHeight = combatLogStackView.frame.height
        let scrollViewHeight = combatLogScrollView.frame.height
        
        if contentHeight > scrollViewHeight {
            let bottomOffset = CGPoint(x: 0, y: contentHeight - scrollViewHeight)
            combatLogScrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    private func addRoundSeparator() {
        let status = CombatService.shared.getGroupCombatStatus()
        let separatorText = "--- Round \(status.round) ---"
        addCombatLogMessage(separatorText, color: .systemGray, isSystemMessage: true)
    }
    
    private func checkCombatEnd() {
        guard let player = player else { return }
        let isPlayerDead = !player.isAlive
        let isNpcDead = !npc.isAlive
        let assistants = npcAssistants
        let anyAssistantsAlive = assistants.contains(where: { $0.isAlive })
        let allEnemiesDead = !anyAssistantsAlive && isNpcDead
        
        if isPlayerDead || allEnemiesDead {
            isCombatEnded = true
            actionsButtonsStack.isUserInteractionEnabled = true
            actionsButtonsStack.isHidden = false
            finishButton.isHidden = true
            
            // Добавляем финальное сообщение в лог
            if isPlayerDead {
                addCombatLogMessage("💀 Your blood stains the cold earth...", color: .systemRed, isSystemMessage: true)
                addCombatLogMessage("Death claims another soul", color: .systemRed, isSystemMessage: true)
            } else {
                let status = CombatService.shared.getGroupCombatStatus()
                if status.totalEnemies > 1 {
                    addCombatLogMessage("🏆 The battlefield falls silent - \(status.totalEnemies) foes lie broken!", color: .systemGreen, isSystemMessage: true)
                } else {
                    addCombatLogMessage("🏆 \(npc.name) draws final breath - victory is yours!", color: .systemGreen, isSystemMessage: true)
                }
            }
        }
        // else: не переключаем автоматически на живого NPC, если выбран мертвый вручную
    }
    
    @objc private func closeCombat() {
        if let onLeave = onLeave {
            GameTimeService.shared.advanceTime()
            onLeave()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func openLoot() {
        if let onLoot = onLoot {
            onLoot()
        }
    }
    
    @objc private func npcCellTapped() {
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
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
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),
            widgetVC.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor, constant: 2),
            widgetVC.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor, constant: 2),
            widgetVC.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor, constant: -2),
            widgetVC.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: -2)
        ])
    }
    
    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        // Выбор ассета: если есть scene, то location{scene.id}, иначе MainSceneBackground
        let scene = GameStateService.shared.currentScene
        let imageName: String
        if let scene = scene {
            let candidate = "location\(scene.id)"
            if UIImage(named: candidate) != nil {
                imageName = candidate
            } else {
                imageName = "MainSceneBackground"
            }
        } else {
            imageName = "MainSceneBackground"
        }
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        view.addSubview(backgroundImageView)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = true
        dustViewHostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(dustViewHostingController)
        view.addSubview(dustViewHostingController.view)
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
    }
    
    private func setupDoubleTapGestures() {
        let playerDoubleTap = UITapGestureRecognizer(target: self, action: #selector(handlePlayerDoubleTap))
        playerDoubleTap.numberOfTapsRequired = 2
        universalPlayerCell.isUserInteractionEnabled = true
        universalPlayerCell.addGestureRecognizer(playerDoubleTap)

        let npcDoubleTap = UITapGestureRecognizer(target: self, action: #selector(handleNpcDoubleTap))
        npcDoubleTap.numberOfTapsRequired = 2
        universalNpcCell.isUserInteractionEnabled = true
        universalNpcCell.addGestureRecognizer(npcDoubleTap)

        // Обычный тап для теста
        let playerTap = UITapGestureRecognizer(target: self, action: #selector(testPlayerTap))
        playerTap.numberOfTapsRequired = 1
        universalPlayerCell.addGestureRecognizer(playerTap)

        let npcTap = UITapGestureRecognizer(target: self, action: #selector(testNpcTap))
        npcTap.numberOfTapsRequired = 1
        universalNpcCell.addGestureRecognizer(npcTap)
    }

    @objc private func handlePlayerDoubleTap() {
        print("Double tap on player cell")
        guard let player = player else { return }
        showWidgetOverlay(type: .player(player))
    }

    @objc private func handleNpcDoubleTap() {
        print("Double tap on npc cell")
        showWidgetOverlay(type: .npc(npc))
    }

    @objc private func testPlayerTap() {
        print("SINGLE tap on player cell")
    }

    @objc private func testNpcTap() {
        print("SINGLE tap on npc cell")
    }

    private enum WidgetType {
        case player(Player)
        case npc(NPC)
    }

    private func showWidgetOverlay(type: WidgetType) {
        // Prevent multiple overlays
        if widgetOverlayView != nil { return }
        // Create overlay
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        overlay.alpha = 0.0
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        widgetOverlayView = overlay
        // Tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissWidgetOverlay))
        overlay.addGestureRecognizer(tap)
        // Create widget
        let widgetVC: UIViewController
        let widgetSize = CGSize(width: 180, height: 320)
        switch type {
        case .player(let player):
            let vc = PlayerWidgetUIViewController(player: player)
            playerWidgetVC = vc
            widgetVC = vc
        case .npc(let npc):
            let vc = NPCWidgetUIViewController(
                npc: npc,
                isSelected: true,
                isDisabled: false,
                showCurrentActivity: true,
                showResistance: false,
                onTap: {},
                onAction: { _ in }
            )
            npcWidgetVC = vc
            widgetVC = vc
        }
        addChild(widgetVC)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.view.alpha = 0.0
        overlay.addSubview(widgetVC.view)
        widgetVC.didMove(toParent: self)
        // Center constraints
        NSLayoutConstraint.activate([
            widgetVC.view.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            widgetVC.view.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            widgetVC.view.widthAnchor.constraint(equalToConstant: widgetSize.width),
            widgetVC.view.heightAnchor.constraint(equalToConstant: widgetSize.height)
        ])
        // Prevent tap-through
        widgetVC.view.isUserInteractionEnabled = true
        // Prevent dismiss when tapping on widget
        let widgetTap = UITapGestureRecognizer(target: self, action: nil)
        widgetVC.view.addGestureRecognizer(widgetTap)
        // Animate in
        UIView.animate(withDuration: 0.22, animations: {
            overlay.alpha = 1.0
        })
        UIView.animate(withDuration: 0.22, delay: 0.05, options: [], animations: {
            widgetVC.view.alpha = 1.0
        }, completion: nil)
    }

    @objc private func dismissWidgetOverlay() {
        guard let overlay = widgetOverlayView else { return }
        // Animate out
        UIView.animate(withDuration: 0.18, animations: {
            overlay.alpha = 0.0
        }, completion: { _ in
            // Remove widget
            self.playerWidgetVC?.willMove(toParent: nil)
            self.playerWidgetVC?.view.removeFromSuperview()
            self.playerWidgetVC?.removeFromParent()
            self.playerWidgetVC = nil
            self.npcWidgetVC?.willMove(toParent: nil)
            self.npcWidgetVC?.view.removeFromSuperview()
            self.npcWidgetVC?.removeFromParent()
            self.npcWidgetVC = nil
            // Remove overlay
            overlay.removeFromSuperview()
            self.widgetOverlayView = nil
        })
    }
}
