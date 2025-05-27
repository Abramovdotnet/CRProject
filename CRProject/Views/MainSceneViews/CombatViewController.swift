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
    // --- Combat Stats Table ---
    private let combatStatsContainer = UIView()
    private let combatStatsImageView = UIImageView()
    private let combatStatsTableView = UIView()
    
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
    
    // Dynamic NPC appearance
    private var isNPCAppearanceInProgress: Bool = false
    private var npcAppearanceTimer: Timer?
    private var pendingNPCs: [NPC] = []
    private var hasMainNPCAppeared: Bool = false
    
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
        combatLogContainer.layer.cornerRadius = 12
        combatLogContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        combatLogContainer.layer.borderWidth = 2
        combatLogContainer.layer.borderColor = UIColor.black.cgColor
        combatLogContainer.layer.shadowColor = UIColor.black.cgColor
        combatLogContainer.layer.shadowOpacity = 0.6
        combatLogContainer.layer.shadowRadius = 8
        combatLogContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.addSubview(combatLogContainer)
        
        // Фоновое изображение для combat log - отключено
        // combatLogImageView.image = UIImage(named: "combatLog3")
        // combatLogImageView.contentMode = .scaleToFill
        // combatLogImageView.translatesAutoresizingMaskIntoConstraints = false
        // combatLogImageView.layer.cornerRadius = 12
        // combatLogImageView.layer.borderWidth = 2
        // combatLogImageView.layer.borderColor = UIColor.black.cgColor
        // combatLogImageView.clipsToBounds = true
        // combatLogContainer.addSubview(combatLogImageView)
        
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

        // Combat Stats Table
        setupCombatStatsTable()

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
            
            // Фоновое изображение combat log - отключено
            // combatLogImageView.topAnchor.constraint(equalTo: combatLogContainer.topAnchor),
            // combatLogImageView.leadingAnchor.constraint(equalTo: combatLogContainer.leadingAnchor),
            // combatLogImageView.trailingAnchor.constraint(equalTo: combatLogContainer.trailingAnchor),
            // combatLogImageView.bottomAnchor.constraint(equalTo: combatLogContainer.bottomAnchor),
            
            // Witness warning label - в верхней части центральной колонки
            witnessWarningLabel.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 16),
            witnessWarningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            witnessWarningLabel.leadingAnchor.constraint(greaterThanOrEqualTo: playerAndActionsStack.trailingAnchor, constant: 16),
            witnessWarningLabel.trailingAnchor.constraint(lessThanOrEqualTo: npcAndActionsStack.leadingAnchor, constant: -16),
            
            // Combat Stats Table - между witness warning и combat log
            combatStatsContainer.topAnchor.constraint(equalTo: witnessWarningLabel.bottomAnchor, constant: 12),
            combatStatsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            combatStatsContainer.widthAnchor.constraint(equalToConstant: 320),
            combatStatsContainer.heightAnchor.constraint(equalToConstant: 120),
            combatStatsContainer.bottomAnchor.constraint(lessThanOrEqualTo: combatLogContainer.topAnchor, constant: -12),
            
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
            
            // Контейнер ассистентов под NPC - выравниваем по левому краю
            npcDeckContainer.leadingAnchor.constraint(equalTo: universalNpcCell.leadingAnchor),
            npcDeckContainer.topAnchor.constraint(equalTo: universalNpcCell.bottomAnchor, constant: 4),
            npcDeckContainer.widthAnchor.constraint(equalToConstant: 125),
            npcDeckContainer.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func setupInitialCombatState() {
        guard let player = player else { return }
        
        // Инициализируем отслеживание состояния игрока
        lastPlayerHealth = player.bloodMeter.currentBlood
        lastPlayerAliveState = player.isAlive
        
        // Настраиваем игрока (он появляется сразу)
        universalPlayerCell.configure(with: player, isDisabled: false)
        playerNameLabel.text = player.name
        
        // Инициализируем combat log
        initializeCombatLog()
        
        // Подготавливаем список NPC для динамического появления
        pendingNPCs = [npc] + npcAssistants
        hasMainNPCAppeared = false
        
        // Скрываем главного NPC и очищаем ассистентов
        universalNpcCell.isHidden = true
        npcNameLabel.text = ""
        for view in npcDeckContainer.subviews { view.removeFromSuperview() }
        assistantNpcCells.removeAll()
        
        // Блокируем все действия
        disableAllActions()
        
        // Запускаем динамическое появление NPC
        startDynamicNPCAppearance()
    }
    
    // MARK: - Dynamic NPC Appearance
    
    private func disableAllActions() {
        isNPCAppearanceInProgress = true
        actionsButtonsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Добавляем заблокированную кнопку с индикатором
        let waitingButton = ActionButtonSmallView(title: "Wait...", icon: "clock.fill", color: .systemGray) { }
        waitingButton.isUserInteractionEnabled = false
        waitingButton.alpha = 0.6
        actionsButtonsStack.addArrangedSubview(waitingButton)
    }
    
    private func enableAllActions() {
        isNPCAppearanceInProgress = false
        setupActionButtons()
    }
    
    private func startDynamicNPCAppearance() {
        guard !pendingNPCs.isEmpty else {
            finalizeCombatSetup()
            return
        }
        
        // Запускаем таймер для появления NPC каждые 0.5 секунды
        npcAppearanceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.addNextNPC()
        }
    }
    
    private func addNextNPC() {
        guard !pendingNPCs.isEmpty else {
            stopNPCAppearance()
            return
        }
        
        let nextNPC = pendingNPCs.removeFirst()
        
        if !hasMainNPCAppeared {
            // Добавляем главного NPC
            addMainNPC(nextNPC)
            hasMainNPCAppeared = true
        } else {
            // Добавляем ассистента
            addAssistantNPC(nextNPC)
        }
        
        // Добавляем сообщение о присоединении к бою
        addCombatLogMessageWithIcons("⚔️ \(nextNPC.name) joins the fight!", initiator: nextNPC, color: .systemRed, isSystemMessage: true)
        
        // Добавляем вибрацию для эффектности
        VibrationService.shared.successVibration()
    }
    
    private func addMainNPC(_ npc: NPC) {
        // Показываем главного NPC с анимацией "вылета"
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        npcNameLabel.text = npc.name
        
        // Сохраняем финальную позицию
        let finalTransform = universalNpcCell.transform
        let finalAlpha: CGFloat = 1.0
        
        // Устанавливаем начальное состояние - далеко справа за экраном
        universalNpcCell.transform = CGAffineTransform(translationX: view.bounds.width + 200, y: -100)
        universalNpcCell.alpha = 0.3
        universalNpcCell.isHidden = false
        
        // Анимация "вылета" с высокой скоростью
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2.0, options: [.curveEaseOut], animations: {
            self.universalNpcCell.transform = finalTransform
            self.universalNpcCell.alpha = finalAlpha
        }, completion: { _ in
            // Небольшой "отскок" для эффектности
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseInOut], animations: {
                self.universalNpcCell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.universalNpcCell.transform = finalTransform
                })

            })
        })
    }
    
    private func addAssistantNPC(_ assistant: NPC) {
        let cellSize: CGFloat = 55
        let cell = UniversalCharacterCellSmall(frame: CGRect(x: 0, y: 0, width: cellSize, height: cellSize))
        cell.configure(with: assistant, isSelected: false, isDisabled: false)
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.clipsToBounds = false
        cell.alpha = 0.3
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAssistantTap(_:)))
        cell.addGestureRecognizer(tap)
        cell.isUserInteractionEnabled = true
        cell.tag = assistantNpcCells.count
        
        npcDeckContainer.addSubview(cell)
        assistantNpcCells.append(cell)
        
        // Обновляем layout для всех ассистентов
        layoutAssistantNPCs()
        
        // Сохраняем финальную позицию
        let finalAlpha: CGFloat = 1.0
        
        // Определяем направление "вылета" в зависимости от индекса
        let assistantIndex = assistantNpcCells.count - 1
        let directions: [(x: CGFloat, y: CGFloat)] = [
            (300, -150),    // Справа сверху
            (-300, -150),   // Слева сверху  
            (350, 200),     // Справа снизу
            (-350, 200),    // Слева снизу
            (0, -300),      // Сверху
            (0, 400)        // Снизу
        ]
        
        let direction = directions[assistantIndex % directions.count]
        
        // Устанавливаем начальную позицию за экраном
        cell.transform = CGAffineTransform(translationX: direction.x, y: direction.y)
        
        // Анимация "вылета" с пружинным эффектом
        let animationDelay = 0.1 // Небольшая задержка для разнообразия
        UIView.animate(withDuration: 0.5, delay: animationDelay, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.8, options: [.curveEaseOut], animations: {
            cell.transform = CGAffineTransform.identity
            cell.alpha = finalAlpha
        }, completion: { _ in
            // Небольшой "отскок" при приземлении
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseInOut], animations: {
                cell.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                         }, completion: { _ in
                 UIView.animate(withDuration: 0.08, animations: {
                     cell.transform = CGAffineTransform.identity
                 })

             })
         })
    }
    
    private func stopNPCAppearance() {
        npcAppearanceTimer?.invalidate()
        npcAppearanceTimer = nil
        finalizeCombatSetup()
    }
    
    private func finalizeCombatSetup() {
        guard let player = player else { return }
        
        // Инициализируем боевую систему после появления всех NPC
        CombatService.shared.startGroupCombat(player: player, primaryNpc: npc, assistants: npcAssistants)
        
        // Обновляем информацию о групповом бое
        updateGroupCombatInfo()
        
        // Устанавливаем начальное количество врагов
        let status = CombatService.shared.getGroupCombatStatus()
        previousAliveEnemiesCount = status.aliveEnemies
        
        // Разблокируем действия
        enableAllActions()
        
        // Показываем и обновляем таблицу характеристик с анимацией
        showCombatStatsTableWithAnimation()
        
        // Проверяем окончание боя
        checkCombatEnd()
        
        // Добавляем финальное сообщение
        addCombatLogMessage("⚔️ Combat begins!", color: .systemYellow, isSystemMessage: true)
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
        
        // Добавляем сообщение о смене цели в лог с иконками
        addCombatLogMessageWithIcons("⚔️ Your gaze turns to \(self.npc.name)", initiator: player, target: self.npc, color: .systemYellow, isSystemMessage: true)
        
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
        let spacing: CGFloat = 8 // Уменьшаем вертикальное расстояние с 12 до 8
        let columnSpacing: CGFloat = 0 // Убираем горизонтальное расстояние полностью для ширины 110px
        
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
        
        // Если идет процесс появления NPC, не показываем кнопки действий
        if isNPCAppearanceInProgress {
            let waitingButton = ActionButtonSmallView(title: "Wait...", icon: "clock.fill", color: .systemGray) { }
            waitingButton.isUserInteractionEnabled = false
            waitingButton.alpha = 0.6
            actionsButtonsStack.addArrangedSubview(waitingButton)
            return
        }
        
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
        for (title, icon, _, handler) in actions {
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
    
    // Маппинг последствий на текст, цвет и персонажей для игрока
    private func prettyCombatResultText(_ summary: String) -> (text: String, color: UIColor, initiator: (any Character)?, target: (any Character)?) {
        let lower = summary.lowercased()
        let isSuccess = lower.contains("success")
        
        var text = ""
        var color = UIColor.white
        
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
            return (text: text, color: color, initiator: npc, target: player)
        } else if summary.contains("feeding interrupted by") {
            text = "🗡️ Blood feast interrupted by enemies"
            color = UIColor.systemOrange
            return (text: text, color: color, initiator: npc, target: player)
        } else if summary.contains("all") && summary.contains("enemies attack") {
            text = "💀 All foes strike in unison"
            color = UIColor.systemRed
            return (text: text, color: color, initiator: npc, target: player)
        } else if summary.contains("dominated (temporarily out of combat)") {
            text = "👁️ mind enslaved, cowering in terror"
            color = UIColor.systemBlue
            return (text: text, color: color, initiator: player, target: npc)
        } else if summary.contains("fed on") {
            text = "🩸 Drained the life essence from"
            color = UIColor.systemPink
            return (text: text, color: color, initiator: player, target: npc)
        } else if summary.contains("drained") && summary.contains("completely") {
            text = "💀 Consumed the very soul of - nothing remains"
            color = UIColor.systemRed
            return (text: text, color: color, initiator: player, target: npc)
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
                    text = "⚔️ Your blade finds flesh - bleeds\(damageInfo)"
                    color = UIColor.systemGreen
                    return (text: text, color: color, initiator: player, target: npc)
                } else {
                    text = "🛡️ Your strike falters - retaliates!"
                    color = UIColor.systemRed
                    return (text: text, color: color, initiator: npc, target: player)
                }
            case let s where s.contains("player_damaged"):
                if isSuccess {
                    text = "🩸 Crimson vitality flows through you!"
                    color = UIColor.systemPink
                    return (text: text, color: color, initiator: player, target: nil)
                } else {
                    let damageInfo = extractDamageInfo(from: summary)
                    text = "🗡️ Steel bites deep into your flesh\(damageInfo)"
                    color = UIColor.systemRed
                    return (text: text, color: color, initiator: npc, target: player)
                }
            case let s where s.contains("target_bited"):
                let healInfo = extractHealInfo(from: summary)
                text = "🩸 Fangs pierce flesh - warm blood sustains you\(healInfo)"
                color = UIColor.systemPink
                return (text: text, color: color, initiator: player, target: npc)
            case let s where s.contains("npc_dominated"):
                text = "👁️ will crumbles before your gaze!"
                color = UIColor.systemBlue
                return (text: text, color: color, initiator: player, target: npc)
            case let s where s.contains("no_effect"):
                text = "— Your efforts prove futile."
                color = UIColor.systemGray
                return (text: text, color: color, initiator: player, target: npc)
            case let s where s.contains("target_drained"):
                text = "💀 life essence flows into the void!"
                color = UIColor.systemRed
                return (text: text, color: color, initiator: player, target: npc)
            default:
                text = summary
                color = UIColor.white
                return (text: text, color: color, initiator: nil, target: nil)
            }
        }
    }
    
    // MARK: - Helper Methods for Damage Extraction
    
    private func extractDamageInfo(from summary: String) -> String {
        // Ищем паттерн (-XX HP) в строке
        let pattern = "\\(-\\d+ HP\\)"
        if let range = summary.range(of: pattern, options: .regularExpression) {
            let match = String(summary[range])
            // Убираем скобки: "(−15 HP)" -> "−15 HP"
            let withoutParentheses = String(match.dropFirst().dropLast())
            return " " + withoutParentheses
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
            let match = String(summary[range])
            // Убираем скобки: "(+10 HP)" -> "+10 HP"
            let withoutParentheses = String(match.dropFirst().dropLast())
            return " " + withoutParentheses
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
        // Получаем информацию о результате действия
        guard let summary = CombatService.shared.resultSummary,
              let actionType = lastActionType else {
            return
        }
        
        let isSuccess = summary.lowercased().contains("success")
        
        // Показываем анимации боевых действий
        if isSuccess {
            // Анимация на цели (NPC)
            showCombatAnimation(for: actionType, isSuccess: true, on: universalNpcCell, isPlayer: false)
            
            // Показываем урон/лечение если есть
            let damageInfo = extractDamageInfo(from: summary)
            let healInfo = extractHealInfo(from: summary)
            
            if !damageInfo.isEmpty {
                showDamageAnimation(on: universalNpcCell, damage: damageInfo, isHealing: false)
            }
            if !healInfo.isEmpty {
                showDamageAnimation(on: universalPlayerCell, damage: healInfo, isHealing: true)
            }
        } else {
            // Анимация промаха/блока на NPC
            showCombatAnimation(for: actionType, isSuccess: false, on: universalNpcCell, isPlayer: false)
            
            // Если игрок получил урон при неудаче - показываем анимацию атаки врага на игроке
            if summary.lowercased().contains("player_damaged") {
                // NPC атакует игрока в ответ
                showCombatAnimation(for: .attack, isSuccess: true, on: universalPlayerCell, isPlayer: true)
                
                let damageInfo = extractDamageInfo(from: summary)
                if !damageInfo.isEmpty {
                    showDamageAnimation(on: universalPlayerCell, damage: damageInfo, isHealing: false)
                }
            }
        }
        
        // Дополнительная проверка для групповых атак на игрока
        if summary.contains("overwhelmed by") || summary.contains("all") && summary.contains("enemies attack") {
            // Множественные атаки на игрока
            showMultipleAttacksOnPlayer()
            
            let damageInfo = extractDamageInfo(from: summary)
            if !damageInfo.isEmpty {
                showDamageAnimation(on: universalPlayerCell, damage: damageInfo, isHealing: false)
            }
        }
        
        // Добавляем результат действия в лог с иконками
        let result = prettyCombatResultText(summary)
        addCombatLogMessageWithIcons(result.text, initiator: result.initiator, target: result.target, color: result.color)
        
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
        
        // Обновляем таблицу характеристик
        updateCombatStatsTable(animated: false)
        
        // Quality of life: автоматически переключаемся на другого живого NPC если текущий умер
        autoSwitchTargetIfNeeded()
        
        checkCombatEnd()
        setupActionButtons()
    }
    
    private func updateGroupCombatInfo() {
        // Эта функция больше не обновляет witness warning label
        // Witness warning label обновляется только в setupActionButtons()
        // Здесь можно добавить другую логику обновления UI если нужно
    }
    
    private func autoSwitchTargetIfNeeded() {
        // Если текущий NPC мертв и бой не закончен, пытаемся переключиться на другого живого
        guard !npc.isAlive && !isCombatEnded else { return }
        
        // Ищем живых ассистентов
        let aliveAssistants = npcAssistants.filter { $0.isAlive }
        
        if let newTarget = aliveAssistants.first {
            // Сохраняем предыдущего NPC
            let previousNPC = self.npc
            
            // Переключаемся на нового живого NPC
            self.npc = newTarget
            self.npcManager.selectedNPC = newTarget
            
            // Удаляем нового главного NPC из ассистентов
            if let index = npcAssistants.firstIndex(where: { $0.id == newTarget.id }) {
                npcAssistants.remove(at: index)
            }
            
            // Добавляем предыдущего мертвого NPC в ассистенты (для отображения)
            npcAssistants.append(previousNPC)
            
            // Обновляем UI
            universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
            npcNameLabel.text = npc.name
            
            // Пересоздаем ассистентов
            setupAssistantNPCs()
            layoutAssistantNPCs()
            
            // Добавляем сообщение о смене цели
            addCombatLogMessageWithIcons("⚔️ Target shifts to \(npc.name) as the battle rages on", initiator: player, target: npc, color: .systemOrange, isSystemMessage: true)
            
            print("Auto-switched target from \(previousNPC.name) (dead) to \(npc.name) (alive)")
        }
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
        // Не добавляем статусные сообщения если бой закончен
        guard !isCombatEnded else { return }
        
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
    
    // MARK: - Combat Animations
    
    private func showCombatAnimation(for actionType: CombatActionType, isSuccess: Bool, on targetWidget: UIView, isPlayer: Bool = false) {
        guard isSuccess else {
            // Показываем анимацию промаха/блока
            showMissAnimation(on: targetWidget)
            return
        }
        
        switch actionType {
        case .attack:
            showSwordAnimation(on: targetWidget, isPlayer: isPlayer)
        case .feed:
            showBiteAnimation(on: targetWidget, isPlayer: isPlayer)
        case .drain:
            showDrainAnimation(on: targetWidget, isPlayer: isPlayer)
        case .dominate:
            showDominateAnimation(on: targetWidget, isPlayer: isPlayer)
        case .defend, .useItem, .escape, .ability, .shadowStep:
            // Для этих действий пока не реализованы анимации
            showMissAnimation(on: targetWidget)
        }
    }
    
    private func showSwordAnimation(on targetWidget: UIView, isPlayer: Bool) {
        let swordLabel = UILabel()
        swordLabel.text = "⚔️"
        swordLabel.font = UIFont.systemFont(ofSize: 50)
        swordLabel.textAlignment = .center
        swordLabel.alpha = 0
        swordLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2).rotated(by: .pi / 2)
        
        targetWidget.superview?.addSubview(swordLabel)
        swordLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swordLabel.centerXAnchor.constraint(equalTo: targetWidget.centerXAnchor),
            swordLabel.centerYAnchor.constraint(equalTo: targetWidget.centerYAnchor)
        ])
        
        // АГРЕССИВНАЯ анимация "рубящего удара"
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseIn], animations: {
            swordLabel.alpha = 1.0
            swordLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5).rotated(by: .pi / 4)
        }, completion: { _ in
            // МОЩНЫЙ удар с тряской
            UIView.animate(withDuration: 0.1, animations: {
                swordLabel.transform = CGAffineTransform(scaleX: 1.8, y: 1.8).rotated(by: -0.2)
                targetWidget.transform = CGAffineTransform(translationX: isPlayer ? 15 : -15, y: 0).scaledBy(x: 0.9, y: 1.1)
            }, completion: { _ in
                // Отскок и тряска
                UIView.animate(withDuration: 0.08, animations: {
                    targetWidget.transform = CGAffineTransform(translationX: isPlayer ? -8 : 8, y: 3).scaledBy(x: 1.05, y: 0.95)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.08, animations: {
                        targetWidget.transform = CGAffineTransform(translationX: isPlayer ? 4 : -4, y: -2).scaledBy(x: 0.98, y: 1.02)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.3, animations: {
                            swordLabel.alpha = 0
                            swordLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3).rotated(by: .pi)
                            targetWidget.transform = CGAffineTransform.identity
                        }, completion: { _ in
                            swordLabel.removeFromSuperview()
                        })
                    })
                })
            })
        })
    }
    
    private func showBiteAnimation(on targetWidget: UIView, isPlayer: Bool) {
        let biteLabel = UILabel()
        biteLabel.text = "🦷"
        biteLabel.font = UIFont.systemFont(ofSize: 45)
        biteLabel.textAlignment = .center
        biteLabel.alpha = 0
        biteLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1).rotated(by: .pi / 3)
        
        targetWidget.superview?.addSubview(biteLabel)
        biteLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            biteLabel.centerXAnchor.constraint(equalTo: targetWidget.centerXAnchor),
            biteLabel.centerYAnchor.constraint(equalTo: targetWidget.centerYAnchor)
        ])
        
        // АГРЕССИВНАЯ анимация "хищного укуса"
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseIn], animations: {
            biteLabel.alpha = 1.0
            biteLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).rotated(by: 0)
        }, completion: { _ in
            // ЖЕСТОКОЕ сжатие челюстей с множественными ударами
            UIView.animate(withDuration: 0.08, animations: {
                biteLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2).rotated(by: -0.3)
                targetWidget.transform = CGAffineTransform(scaleX: 0.85, y: 1.15).rotated(by: 0.1)
            }, completion: { _ in
                UIView.animate(withDuration: 0.06, animations: {
                    biteLabel.transform = CGAffineTransform(scaleX: 1.4, y: 1.4).rotated(by: 0.2)
                    targetWidget.transform = CGAffineTransform(scaleX: 0.9, y: 1.1).rotated(by: -0.08)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.06, animations: {
                        biteLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1).rotated(by: -0.15)
                        targetWidget.transform = CGAffineTransform(scaleX: 0.88, y: 1.12).rotated(by: 0.05)
                    }, completion: { _ in
                        // Финальное "разрывание"
                        UIView.animate(withDuration: 0.2, animations: {
                            biteLabel.alpha = 0
                            biteLabel.transform = CGAffineTransform(scaleX: 2.0, y: 0.3).rotated(by: .pi / 2)
                            targetWidget.transform = CGAffineTransform.identity
                        }, completion: { _ in
                            biteLabel.removeFromSuperview()
                        })
                    })
                })
            })
        })
    }
    
    private func showDrainAnimation(on targetWidget: UIView, isPlayer: Bool) {
        // Создаем множественные капли крови для более агрессивного эффекта
        for i in 0..<5 {
            let drainLabel = UILabel()
            drainLabel.text = "🩸"
            drainLabel.font = UIFont.systemFont(ofSize: 25 + CGFloat(i * 3))
            drainLabel.textAlignment = .center
            drainLabel.alpha = 0
            drainLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2).rotated(by: CGFloat.random(in: -0.5...0.5))
            
            targetWidget.superview?.addSubview(drainLabel)
            drainLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                drainLabel.centerXAnchor.constraint(equalTo: targetWidget.centerXAnchor, constant: CGFloat.random(in: -15...15)),
                drainLabel.centerYAnchor.constraint(equalTo: targetWidget.centerYAnchor, constant: CGFloat.random(in: -15...15))
            ])
            
            let delay = Double(i) * 0.05
            
            // АГРЕССИВНАЯ анимация "кровавого дрейна"
            UIView.animate(withDuration: 0.15, delay: delay, options: [.curveEaseOut], animations: {
                drainLabel.alpha = 1.0
                drainLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3).rotated(by: CGFloat.random(in: -0.3...0.3))
            }, completion: { _ in
                // Кровь "вырывается" из цели
                UIView.animate(withDuration: 0.2, animations: {
                    drainLabel.center = CGPoint(
                        x: drainLabel.center.x + CGFloat.random(in: -40...40),
                        y: drainLabel.center.y - CGFloat.random(in: 30...60)
                    )
                    drainLabel.transform = CGAffineTransform(scaleX: 1.8, y: 1.8).rotated(by: CGFloat.random(in: -1...1))
                }, completion: { _ in
                    // Кровь исчезает с эффектом "поглощения"
                    UIView.animate(withDuration: 0.25, animations: {
                        drainLabel.alpha = 0
                        drainLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                        drainLabel.center = CGPoint(x: drainLabel.center.x, y: drainLabel.center.y - 20)
                    }, completion: { _ in
                        drainLabel.removeFromSuperview()
                    })
                })
            })
        }
        
        // Эффект на цель - более агрессивное "высушивание"
        UIView.animate(withDuration: 0.3, delay: 0.1, animations: {
            targetWidget.alpha = 0.4
            targetWidget.transform = CGAffineTransform(scaleX: 0.85, y: 0.85).rotated(by: 0.1)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15, animations: {
                targetWidget.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).rotated(by: -0.05)
            }, completion: { _ in
                UIView.animate(withDuration: 0.4, animations: {
                    targetWidget.alpha = 1.0
                    targetWidget.transform = CGAffineTransform.identity
                })
            })
        })
    }
    
    private func showDominateAnimation(on targetWidget: UIView, isPlayer: Bool) {
        let eyeLabel = UILabel()
        eyeLabel.text = "👁️"
        eyeLabel.font = UIFont.systemFont(ofSize: 50)
        eyeLabel.textAlignment = .center
        eyeLabel.alpha = 0
        eyeLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        targetWidget.superview?.addSubview(eyeLabel)
        eyeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eyeLabel.centerXAnchor.constraint(equalTo: targetWidget.centerXAnchor),
            eyeLabel.centerYAnchor.constraint(equalTo: targetWidget.centerYAnchor)
        ])
        
        // АГРЕССИВНАЯ анимация "ментального подавления"
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            eyeLabel.alpha = 1.0
            eyeLabel.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
        }, completion: { _ in
            // ИНТЕНСИВНАЯ пульсация с нарастающей силой
            var pulseCount = 0
            let maxPulses = 6
            
            func performPulse() {
                guard pulseCount < maxPulses else {
                    // Финальное "сокрушение воли"
                    UIView.animate(withDuration: 0.15, animations: {
                        eyeLabel.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
                        targetWidget.alpha = 0.3
                        targetWidget.transform = CGAffineTransform(scaleX: 0.7, y: 0.7).rotated(by: 0.2)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.1, animations: {
                            targetWidget.transform = CGAffineTransform(scaleX: 0.75, y: 0.75).rotated(by: -0.15)
                        }, completion: { _ in
                            UIView.animate(withDuration: 0.1, animations: {
                                targetWidget.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).rotated(by: 0.1)
                            }, completion: { _ in
                                UIView.animate(withDuration: 0.3, animations: {
                                    eyeLabel.alpha = 0
                                    eyeLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                                    targetWidget.alpha = 1.0
                                    targetWidget.transform = CGAffineTransform.identity
                                }, completion: { _ in
                                    eyeLabel.removeFromSuperview()
                                })
                            })
                        })
                    })
                    return
                }
                
                let intensity = 1.8 + (CGFloat(pulseCount) * 0.15)
                UIView.animate(withDuration: 0.08, animations: {
                    eyeLabel.transform = CGAffineTransform(scaleX: intensity, y: intensity)
                    targetWidget.transform = CGAffineTransform(scaleX: 0.95 - CGFloat(pulseCount) * 0.03, y: 0.95 - CGFloat(pulseCount) * 0.03)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.08, animations: {
                        eyeLabel.transform = CGAffineTransform(scaleX: intensity - 0.2, y: intensity - 0.2)
                    }, completion: { _ in
                        pulseCount += 1
                        performPulse()
                    })
                })
            }
            
            performPulse()
        })
    }
    
    private func showMissAnimation(on targetWidget: UIView) {
        let missLabel = UILabel()
        missLabel.text = "🛡️"
        missLabel.font = UIFont.systemFont(ofSize: 40)
        missLabel.textAlignment = .center
        missLabel.alpha = 0
        missLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2).rotated(by: .pi / 4)
        
        targetWidget.superview?.addSubview(missLabel)
        missLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            missLabel.centerXAnchor.constraint(equalTo: targetWidget.centerXAnchor),
            missLabel.centerYAnchor.constraint(equalTo: targetWidget.centerYAnchor)
        ])
        
        // АГРЕССИВНАЯ анимация "мощного блока"
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut], animations: {
            missLabel.alpha = 1.0
            missLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).rotated(by: 0)
            targetWidget.transform = CGAffineTransform(translationX: 8, y: -8).scaledBy(x: 1.05, y: 0.95)
        }, completion: { _ in
            // Отскок от блока
            UIView.animate(withDuration: 0.08, animations: {
                missLabel.transform = CGAffineTransform(scaleX: 1.8, y: 1.8).rotated(by: -0.2)
                targetWidget.transform = CGAffineTransform(translationX: -4, y: 4).scaledBy(x: 0.98, y: 1.02)
            }, completion: { _ in
                UIView.animate(withDuration: 0.08, animations: {
                    targetWidget.transform = CGAffineTransform(translationX: 2, y: -2).scaledBy(x: 1.01, y: 0.99)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.3, animations: {
                        missLabel.alpha = 0
                        missLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2).rotated(by: .pi)
                        targetWidget.transform = CGAffineTransform.identity
                    }, completion: { _ in
                        missLabel.removeFromSuperview()
                    })
                })
            })
        })
    }
    
    private func showMultipleAttacksOnPlayer() {
        // Показываем 3-5 мечей атакующих игрока одновременно
        let attackCount = Int.random(in: 3...5)
        
        for i in 0..<attackCount {
            let delay = Double(i) * 0.1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                let swordLabel = UILabel()
                swordLabel.text = "⚔️"
                swordLabel.font = UIFont.systemFont(ofSize: 35 + CGFloat(i * 3))
                swordLabel.textAlignment = .center
                swordLabel.alpha = 0
                swordLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1).rotated(by: CGFloat.random(in: 0...(.pi * 2)))
                
                self.universalPlayerCell.superview?.addSubview(swordLabel)
                swordLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    swordLabel.centerXAnchor.constraint(equalTo: self.universalPlayerCell.centerXAnchor, constant: CGFloat.random(in: -40...40)),
                    swordLabel.centerYAnchor.constraint(equalTo: self.universalPlayerCell.centerYAnchor, constant: CGFloat.random(in: -30...30))
                ])
                
                // Быстрая атака
                UIView.animate(withDuration: 0.15, animations: {
                    swordLabel.alpha = 1.0
                    swordLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3).rotated(by: CGFloat.random(in: -0.5...0.5))
                }, completion: { _ in
                    UIView.animate(withDuration: 0.1, animations: {
                        swordLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5).rotated(by: CGFloat.random(in: -0.3...0.3))
                        self.universalPlayerCell.transform = CGAffineTransform(
                            translationX: CGFloat.random(in: -8...8),
                            y: CGFloat.random(in: -8...8)
                        ).scaledBy(x: 0.95, y: 1.05)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.25, animations: {
                            swordLabel.alpha = 0
                            swordLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                            if i == attackCount - 1 {
                                // Последняя атака - возвращаем игрока в нормальное состояние
                                self.universalPlayerCell.transform = CGAffineTransform.identity
                            }
                        }, completion: { _ in
                            swordLabel.removeFromSuperview()
                        })
                    })
                })
            }
        }
    }
    
    private func showDamageAnimation(on targetWidget: UIView, damage: String, isHealing: Bool = false) {
        let damageLabel = UILabel()
        damageLabel.text = damage
        damageLabel.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)
        damageLabel.textColor = isHealing ? .systemGreen : .systemRed
        damageLabel.textAlignment = .center
        damageLabel.alpha = 0
        damageLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        // Добавляем тень для лучшей видимости
        damageLabel.layer.shadowColor = UIColor.black.cgColor
        damageLabel.layer.shadowOpacity = 0.8
        damageLabel.layer.shadowRadius = 2
        damageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        targetWidget.superview?.addSubview(damageLabel)
        damageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            damageLabel.centerXAnchor.constraint(equalTo: targetWidget.centerXAnchor),
            damageLabel.centerYAnchor.constraint(equalTo: targetWidget.centerYAnchor, constant: 25)
        ])
        
        // Анимация "всплывающего урона"
        UIView.animate(withDuration: 0.3, delay: 0.2, options: [.curveEaseOut], animations: {
            damageLabel.alpha = 1.0
            damageLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            damageLabel.center = CGPoint(x: damageLabel.center.x, y: damageLabel.center.y - 40)
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, animations: {
                damageLabel.alpha = 0
                damageLabel.center = CGPoint(x: damageLabel.center.x, y: damageLabel.center.y - 20)
            }, completion: { _ in
                damageLabel.removeFromSuperview()
            })
        })
    }

    // MARK: - Combat Log Methods
    
    private func createCharacterIcon(for character: any Character, size: CGFloat = 30) -> UIImageView {
        let iconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 10
        iconView.layer.borderWidth = 0.5
        iconView.layer.borderColor = UIColor.black.cgColor
        
        // Фиксируем размеры через constraints
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        if let player = character as? Player {
            iconView.image = UIImage(named: "player1") ?? UIImage(named: "player_avatar") ?? UIImage(systemName: "person.circle.fill")
            iconView.tintColor = .systemBlue
        } else if let npc = character as? NPC {
            iconView.image = UIImage(named: "npc\(npc.id)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder") ?? UIImage(systemName: "person.circle")
            iconView.tintColor = .systemRed
        }
        
        return iconView
    }
    
    private func addCombatLogMessageWithIcons(_ text: String, initiator: (any Character)? = nil, target: (any Character)? = nil, color: UIColor = .white, isSystemMessage: Bool = false) {
        // Не добавляем сообщения если бой закончен
        guard !isCombatEnded else { return }
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем иконку инициатора
        if let initiator = initiator {
            let initiatorIcon = createCharacterIcon(for: initiator)
            stackView.addArrangedSubview(initiatorIcon)
        }
        
        // Добавляем текст сообщения
        let messageLabel = UILabel()
        messageLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
        messageLabel.textColor = color
        messageLabel.textAlignment = isSystemMessage ? .center : .left
        messageLabel.numberOfLines = 0
        messageLabel.text = text
        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Добавляем тень для лучшей читаемости
        messageLabel.layer.shadowColor = UIColor.black.cgColor
        messageLabel.layer.shadowOpacity = 0.7
        messageLabel.layer.shadowRadius = 2
        messageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        stackView.addArrangedSubview(messageLabel)
        
        // Добавляем иконку цели
        if let target = target {
            let targetIcon = createCharacterIcon(for: target)
            stackView.addArrangedSubview(targetIcon)
        }
        
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        combatLogStackView.addArrangedSubview(containerView)
        
        // Автоматически прокручиваем вниз
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }
    
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
        // Не добавляем сообщения если бой закончен
        guard !isCombatEnded else { return }
        
        let messageLabel = UILabel()
        messageLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
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
            // Добавляем финальное сообщение в лог ПЕРЕД установкой флага завершения
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
            
            // Устанавливаем флаг завершения боя ПОСЛЕ добавления сообщений
            isCombatEnded = true
            actionsButtonsStack.isUserInteractionEnabled = true
            actionsButtonsStack.isHidden = false
            finishButton.isHidden = true
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
    
    // MARK: - Combat Stats Table
    
    private func setupCombatStatsTable() {
        combatStatsContainer.translatesAutoresizingMaskIntoConstraints = false
        combatStatsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        combatStatsContainer.layer.cornerRadius = 12
        combatStatsContainer.layer.borderWidth = 2
        combatStatsContainer.layer.borderColor = UIColor.black.cgColor
        combatStatsContainer.layer.shadowColor = UIColor.black.cgColor
        combatStatsContainer.layer.shadowOpacity = 0.6
        combatStatsContainer.layer.shadowRadius = 8
        combatStatsContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        combatStatsContainer.clipsToBounds = false // Изменяем на false для отображения тени
        combatStatsContainer.isHidden = true // Скрываем до начала боя
        view.addSubview(combatStatsContainer)
        
        // Фоновое изображение для combat stats table - отключено
        // combatStatsImageView.image = UIImage(named: "combatLog3")
        // combatStatsImageView.contentMode = .scaleToFill
        // combatStatsImageView.translatesAutoresizingMaskIntoConstraints = false
        // combatStatsImageView.layer.cornerRadius = 12
        // combatStatsImageView.layer.borderWidth = 2
        // combatStatsImageView.layer.borderColor = UIColor.black.cgColor
        // combatStatsImageView.clipsToBounds = true
        // combatStatsContainer.addSubview(combatStatsImageView)
        
        combatStatsTableView.translatesAutoresizingMaskIntoConstraints = false
        combatStatsTableView.clipsToBounds = true
        combatStatsContainer.addSubview(combatStatsTableView)
        
        NSLayoutConstraint.activate([
            // Фоновое изображение combat stats table - отключено
            // combatStatsImageView.topAnchor.constraint(equalTo: combatStatsContainer.topAnchor),
            // combatStatsImageView.leadingAnchor.constraint(equalTo: combatStatsContainer.leadingAnchor),
            // combatStatsImageView.trailingAnchor.constraint(equalTo: combatStatsContainer.trailingAnchor),
            // combatStatsImageView.bottomAnchor.constraint(equalTo: combatStatsContainer.bottomAnchor),
            
            combatStatsTableView.topAnchor.constraint(equalTo: combatStatsContainer.topAnchor, constant: 8),
            combatStatsTableView.leadingAnchor.constraint(equalTo: combatStatsContainer.leadingAnchor, constant: 8),
            combatStatsTableView.trailingAnchor.constraint(equalTo: combatStatsContainer.trailingAnchor, constant: -8),
            combatStatsTableView.bottomAnchor.constraint(equalTo: combatStatsContainer.bottomAnchor, constant: -8)
        ])
    }
    
    private func updateCombatStatsTable(animated: Bool = true) {
        // Очищаем предыдущее содержимое
        combatStatsTableView.subviews.forEach { $0.removeFromSuperview() }
        
        guard let player = player else { return }
        
        // Получаем характеристики
        let playerAttack = player.getAttackValue()
        let playerDefense = player.getDefenseValue()
        
        let aliveEnemies = getAllAliveEnemies()
        let totalEnemyAttack = aliveEnemies.reduce(0) { $0 + $1.getAttackValue() }
        let totalEnemyDefense = aliveEnemies.reduce(0) { $0 + $1.getDefenseValue() }
        
        // Создаем заголовки колонок
        let playerHeaderStack = createHeaderStack(title: "Player", iconName: "person.circle.fill", color: .systemBlue)
        let enemiesHeaderStack = createHeaderStack(title: "Enemies", iconName: "person.3.fill", color: .systemRed)
        
        // Создаем строки характеристик
        let attackRow = createStatsRow(
            leftIcon: "sword.fill",
            leftTitle: "Attack",
            leftValue: animated ? "0" : "\(playerAttack)",
            leftTag: 1001,
            rightIcon: "sword.fill", 
            rightTitle: "Attack",
            rightValue: animated ? "0" : "\(totalEnemyAttack)",
            rightTag: 1003
        )
        
        let defenseRow = createStatsRow(
            leftIcon: "shield.fill",
            leftTitle: "Defense", 
            leftValue: animated ? "0" : "\(playerDefense)",
            leftTag: 1002,
            rightIcon: "shield.fill",
            rightTitle: "Defense",
            rightValue: animated ? "0" : "\(totalEnemyDefense)",
            rightTag: 1004
        )
        
        // Разделитель
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.systemGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Итоговые значения
        let totalDamageToEnemies = max(1, playerAttack - (aliveEnemies.first?.getDefenseValue() ?? 0))
        let totalDamageToPlayer = max(1, totalEnemyAttack - playerDefense)
        
        let totalRow = createStatsRow(
            leftIcon: "bolt.fill",
            leftTitle: "Total Damage",
            leftValue: animated ? "0" : "\(totalDamageToEnemies)",
            leftTag: 1005,
            rightIcon: "bolt.fill",
            rightTitle: "Total Damage", 
            rightValue: animated ? "0" : "\(totalDamageToPlayer)",
            rightTag: 1006
        )
        
        // Добавляем все элементы
        combatStatsTableView.addSubview(playerHeaderStack)
        combatStatsTableView.addSubview(enemiesHeaderStack)
        combatStatsTableView.addSubview(attackRow)
        combatStatsTableView.addSubview(defenseRow)
        combatStatsTableView.addSubview(separatorView)
        combatStatsTableView.addSubview(totalRow)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Headers
            playerHeaderStack.topAnchor.constraint(equalTo: combatStatsTableView.topAnchor),
            playerHeaderStack.leadingAnchor.constraint(equalTo: combatStatsTableView.leadingAnchor),
            playerHeaderStack.widthAnchor.constraint(equalTo: combatStatsTableView.widthAnchor, multiplier: 0.48),
            
            enemiesHeaderStack.topAnchor.constraint(equalTo: combatStatsTableView.topAnchor),
            enemiesHeaderStack.trailingAnchor.constraint(equalTo: combatStatsTableView.trailingAnchor),
            enemiesHeaderStack.widthAnchor.constraint(equalTo: combatStatsTableView.widthAnchor, multiplier: 0.48),
            
            // Attack row
            attackRow.topAnchor.constraint(equalTo: playerHeaderStack.bottomAnchor, constant: 4),
            attackRow.leadingAnchor.constraint(equalTo: combatStatsTableView.leadingAnchor),
            attackRow.trailingAnchor.constraint(equalTo: combatStatsTableView.trailingAnchor),
            attackRow.heightAnchor.constraint(equalToConstant: 20),
            
            // Defense row
            defenseRow.topAnchor.constraint(equalTo: attackRow.bottomAnchor, constant: 2),
            defenseRow.leadingAnchor.constraint(equalTo: combatStatsTableView.leadingAnchor),
            defenseRow.trailingAnchor.constraint(equalTo: combatStatsTableView.trailingAnchor),
            defenseRow.heightAnchor.constraint(equalToConstant: 20),
            
            // Separator
            separatorView.topAnchor.constraint(equalTo: defenseRow.bottomAnchor, constant: 4),
            separatorView.leadingAnchor.constraint(equalTo: combatStatsTableView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: combatStatsTableView.trailingAnchor, constant: -20),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Total row
            totalRow.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 4),
            totalRow.leadingAnchor.constraint(equalTo: combatStatsTableView.leadingAnchor),
            totalRow.trailingAnchor.constraint(equalTo: combatStatsTableView.trailingAnchor),
            totalRow.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func createHeaderStack(title: String, iconName: String, color: UIColor) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = color
        titleLabel.textAlignment = .center
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        
        return stack
    }
    
    private func createStatsRow(leftIcon: String, leftTitle: String, leftValue: String, leftTag: Int,
                               rightIcon: String, rightTitle: String, rightValue: String, rightTag: Int) -> UIView {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        // Left side
        let leftStack = createStatItem(icon: leftIcon, title: leftTitle, value: leftValue, tag: leftTag, color: .systemBlue)
        
        // Right side  
        let rightStack = createStatItem(icon: rightIcon, title: rightTitle, value: rightValue, tag: rightTag, color: .systemRed)
        
        rowView.addSubview(leftStack)
        rowView.addSubview(rightStack)
        
        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            leftStack.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            leftStack.widthAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: 0.48),
            
            rightStack.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            rightStack.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            rightStack.widthAnchor.constraint(equalTo: rowView.widthAnchor, multiplier: 0.48)
        ])
        
        return rowView
    }
    
    private func createStatItem(icon: String, title: String, value: String, tag: Int, color: UIColor) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
        titleLabel.textColor = .white
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
        valueLabel.textColor = color
        valueLabel.tag = tag // Устанавливаем тег для анимации
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        
        return stack
    }
    
    private func getAllAliveEnemies() -> [NPC] {
        var enemies = [npc].compactMap { $0 }
        enemies.append(contentsOf: npcAssistants)
        return enemies.filter { $0.isAlive }
    }
    
    private func showCombatStatsTableWithAnimation() {
        // Устанавливаем начальное состояние
        combatStatsContainer.alpha = 0
        combatStatsContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        combatStatsContainer.isHidden = false
        
        // Сначала обновляем содержимое с нулевыми значениями
        updateCombatStatsTable(animated: true)
        
        // Анимация появления контейнера
        UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
            self.combatStatsContainer.alpha = 1.0
            self.combatStatsContainer.transform = CGAffineTransform.identity
        }, completion: { _ in
            // После появления контейнера анимируем числа
            self.animateStatsNumbers()
        })
    }
    
    private func animateStatsNumbers() {
        guard let player = player else { return }
        
        // Получаем финальные значения
        let playerAttack = player.getAttackValue()
        let playerDefense = player.getDefenseValue()
        
        let aliveEnemies = getAllAliveEnemies()
        let totalEnemyAttack = aliveEnemies.reduce(0) { $0 + $1.getAttackValue() }
        let totalEnemyDefense = aliveEnemies.reduce(0) { $0 + $1.getDefenseValue() }
        
        let totalDamageToEnemies = max(1, playerAttack - (aliveEnemies.first?.getDefenseValue() ?? 0))
        let totalDamageToPlayer = max(1, totalEnemyAttack - playerDefense)
        
        // Анимируем каждое число с задержкой
        animateNumberLabel(tag: 1001, to: playerAttack, delay: 0.0)
        animateNumberLabel(tag: 1002, to: playerDefense, delay: 0.1)
        animateNumberLabel(tag: 1003, to: totalEnemyAttack, delay: 0.2)
        animateNumberLabel(tag: 1004, to: totalEnemyDefense, delay: 0.3)
        animateNumberLabel(tag: 1005, to: totalDamageToEnemies, delay: 0.5)
        animateNumberLabel(tag: 1006, to: totalDamageToPlayer, delay: 0.6)
    }
    
    private func animateNumberLabel(tag: Int, to finalValue: Int, delay: TimeInterval) {
        guard let label = combatStatsTableView.viewWithTag(tag) as? UILabel else { return }
        
        let duration: TimeInterval = 1.0
        let steps = 30
        let stepDuration = duration / Double(steps)
        
        var currentStep = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            let progress = Double(currentStep) / Double(steps)
            
            // Используем easeOut функцию для плавности
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            let currentValue = Int(Double(finalValue) * easedProgress)
            
            DispatchQueue.main.async {
                label.text = "\(currentValue)"
                
                // Добавляем небольшой эффект масштабирования
                if currentStep == steps {
                    UIView.animate(withDuration: 0.2, animations: {
                        label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.15, animations: {
                            label.transform = CGAffineTransform.identity
                        })
                    })
                }
            }
            
            if currentStep >= steps {
                timer.invalidate()
            }
        }
        
        // Запускаем таймер с задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            timer.fire()
        }
    }
    
    deinit {
        print("CombatViewController deinit")
        npcAppearanceTimer?.invalidate()
        npcAppearanceTimer = nil
    }
}
