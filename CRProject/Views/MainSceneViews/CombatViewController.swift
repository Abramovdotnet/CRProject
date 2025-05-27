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
    private let combatLogTextLabel = UILabel()
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
        combatLogContainer.addSubview(witnessWarningLabel)

        // VS label убран
        
        // Combat log text
        combatLogTextLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        combatLogTextLabel.textColor = .white
        combatLogTextLabel.textAlignment = .center
        combatLogTextLabel.numberOfLines = 0
        combatLogTextLabel.translatesAutoresizingMaskIntoConstraints = false
        combatLogTextLabel.layer.shadowColor = UIColor.black.cgColor
        combatLogTextLabel.layer.shadowOpacity = 0.7
        combatLogTextLabel.layer.shadowRadius = 3
        combatLogTextLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        combatLogContainer.addSubview(combatLogTextLabel)

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
            
            // 2 столбец - центральный контейнер (ширина второго столбца - 10)
            combatLogContainer.leadingAnchor.constraint(equalTo: playerAndActionsStack.trailingAnchor, constant: 21),
            combatLogContainer.trailingAnchor.constraint(equalTo: npcAndActionsStack.leadingAnchor, constant: -21),
            combatLogContainer.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 40),
            combatLogContainer.heightAnchor.constraint(equalToConstant: 300),
            
            // Фон контейнера - временно убран
            
            // Элементы внутри контейнера
            witnessWarningLabel.topAnchor.constraint(equalTo: combatLogContainer.topAnchor, constant: 24),
            witnessWarningLabel.leadingAnchor.constraint(equalTo: combatLogContainer.leadingAnchor, constant: 16),
            witnessWarningLabel.trailingAnchor.constraint(equalTo: combatLogContainer.trailingAnchor, constant: -16),
            
            combatLogTextLabel.topAnchor.constraint(equalTo: witnessWarningLabel.bottomAnchor, constant: 40),
            combatLogTextLabel.leadingAnchor.constraint(equalTo: combatLogContainer.leadingAnchor, constant: 16),
            combatLogTextLabel.trailingAnchor.constraint(equalTo: combatLogContainer.trailingAnchor, constant: -16),
            combatLogTextLabel.bottomAnchor.constraint(lessThanOrEqualTo: combatLogContainer.bottomAnchor, constant: -16),
            
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
        CombatService.shared.startCombat(player: player, npc: npc)
        universalPlayerCell.configure(with: player, isDisabled: false)
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        
        // Устанавливаем имена
        playerNameLabel.text = player.name
        npcNameLabel.text = npc.name
        
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
        
        setupActionButtons()
        updateUIAfterAction()
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
        updateUIAfterAction()
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
                CombatService.shared.performAction(action)
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
                CombatService.shared.performAction(action)
                self.updateUIAfterAction()
            }),
            ("Drain", "drop.triangle.fill", .systemRed, { [weak self] in
                guard let self = self else { return }
                self.lastActionType = .feed
                let action = CombatAction(
                    type: .feed,
                    initiatorId: "",
                    target: self.npc,
                    parameters: nil
                )
                CombatService.shared.performAction(action)
                self.updateUIAfterAction()
            }),
        ]

        if AbilitiesSystem.shared.hasDomination {
            actions.insert(
                ("Dominate", "eye", .systemBlue, { [weak self] in
                guard let self = self else { return }
                self.lastActionType = .feed
                let action = CombatAction(
                    type: .feed,
                    initiatorId: "",
                    target: self.npc,
                    parameters: nil
                )
                CombatService.shared.performAction(action)
                self.updateUIAfterAction()
                }), at: 2)
        }
        let witnesses = GameStateService.shared.getAwakeNpcsCount()
        let hasVampireAction = actions.contains(where: { $0.title == "Bite" || $0.title == "Drain" || $0.title == "Dominate" })
        if witnesses > 0 && hasVampireAction {
            witnessWarningLabel.text = "⚠️ There are witnesses! Actions will have consequences. (\(witnesses))"
            witnessWarningLabel.textColor = UIColor.systemRed
            witnessWarningLabel.isHidden = false
        } else if hasVampireAction {
            witnessWarningLabel.text = "🌑 No one is watching... The night is yours."
            witnessWarningLabel.textColor = UIColor.systemGreen
            witnessWarningLabel.isHidden = false
        } else {
            witnessWarningLabel.isHidden = true
        }
        for (title, icon, color, handler) in actions {
            // Получаем шанс успеха
            let chance = CombatService.shared.getBaseChance(for: CombatActionType(rawValue: actions.firstIndex(where: { $0.title == title }) ?? 0) ?? .attack)
            let chancePercent = Int(chance * 100)
            let button = ActionButtonSmallView(title: title, icon: icon, color: color, onTap: handler)
            button.setSubtitle("\(chancePercent)%")
            // --- Делаем кнопку неактивной, если NPC мертв ---
            button.isEnabled = npc.isAlive
            button.alpha = npc.isAlive ? 1.0 : 0.7
            actionsButtonsStack.addArrangedSubview(button)
        }
    }
    
    // Маппинг последствий на текст, цвет и иконку для игрока
    private func prettyCombatResultText(_ summary: String) -> (NSAttributedString, UIColor) {
        // Примеры: "Success: damage_caused", "Fail: player_damaged"
        let lower = summary.lowercased()
        let isSuccess = lower.contains("success")
        let isFail = lower.contains("fail")
        let code: String = {
            if let idx = lower.firstIndex(of: ":") {
                return lower[lower.index(after: idx)...].trimmingCharacters(in: .whitespaces)
            }
            return lower
        }()
        var text = ""
        var color = UIColor.white
        var icon = ""
        switch code {
        case let s where s.contains("damage_caused"):
            text = isSuccess ? "You hit \(self.npc.name)" : "Missed! \(self.npc.name) strikes back!"
            color = isSuccess ? UIColor.systemGreen : UIColor.systemRed
            icon = isSuccess ? "🗡️" : "💢"
        case let s where s.contains("player_damaged"):
            text = isSuccess ? "You heal!" : "You are hurt!"
            color = isSuccess ? UIColor.systemPink : UIColor.systemRed
            icon = isSuccess ? "🩸" : "💢"
        case let s where s.contains("target_bited"):
            text = "You bite and heal!"
            color = UIColor.systemPink
            icon = "🩸"
        case let s where s.contains("npc_dominated"):
            text = "\(self.npc.name) is dominated!"
            color = UIColor.systemBlue
            icon = "👁️"
        case let s where s.contains("no_effect"):
            text = "No effect."
            color = UIColor.systemGray
            icon = "—"
        case let s where s.contains("target_drained"):
            text = "You drain all \(self.npc.name) blood!"
            color = UIColor.systemRed
            icon = "🩸"
        default:
            text = summary
            color = UIColor.white
            icon = ""
        }
        let pretty = NSMutableAttributedString(string: icon.isEmpty ? text : icon + " " + text)
        pretty.addAttribute(.font, value: UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18), range: NSRange(location: 0, length: pretty.length))
        pretty.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: pretty.length))
        return (pretty, color)
    }
    
    private func updateUIAfterAction() {
        if let summary = CombatService.shared.resultSummary {
            let (pretty, _) = prettyCombatResultText(summary)
            combatLogTextLabel.attributedText = pretty
        } else {
            combatLogTextLabel.text = ""
        }
        if let player = player {
            universalPlayerCell.configure(with: player, isDisabled: false)
        }
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        // --- Обновляем ассистентов ---
        //setupAssistantNPCs()
        checkCombatEnd()
        setupActionButtons()
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
            combatLogTextLabel.text = isPlayerDead ? "You died!" : "Enemy defeated!"
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
