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
    private let universalPlayerCell = UniversalCharacterCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    private let universalNpcCell = UniversalCharacterCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    private let vsLabel = UILabel()
    private let actionsStack = UIStackView()
    private let resultLabel = UILabel()
    private let finishButton = UIButton(type: .system)
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    // Кнопки после завершения боя
    private let witnessWarningLabel = UILabel()
    private let centerWidgetsContainer = UIView()
    // Overlay and widget references
    private var widgetOverlayView: UIView?
    private var playerWidgetVC: PlayerWidgetUIViewController?
    private var npcWidgetVC: NPCWidgetUIViewController?
    // --- Assistants UI ---
    private var assistantNpcCells: [UniversalCharacterCell] = []
    
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
        // --- Предупреждение о свидетелях/атмосфере ---
        witnessWarningLabel.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18)
        witnessWarningLabel.textColor = UIColor.systemRed
        witnessWarningLabel.textAlignment = .center
        witnessWarningLabel.numberOfLines = 2
        witnessWarningLabel.layer.shadowColor = UIColor.black.cgColor
        witnessWarningLabel.layer.shadowOpacity = 0.7
        witnessWarningLabel.layer.shadowRadius = 3
        witnessWarningLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        witnessWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(witnessWarningLabel)

        // VS label
        vsLabel.text = "VS"
        vsLabel.font = UIFont(name: "Optima-Regular", size: 40) ?? UIFont.systemFont(ofSize: 40)
        vsLabel.textColor = .systemRed
        vsLabel.textAlignment = .center
        vsLabel.translatesAutoresizingMaskIntoConstraints = false
        vsLabel.layer.shadowColor = UIColor.black.cgColor
        vsLabel.layer.shadowOpacity = 0.7
        vsLabel.layer.shadowRadius = 3
        vsLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
      

        // Actions stack (vertical, отдельно)
        actionsStack.axis = .vertical
        actionsStack.alignment = .leading
        actionsStack.spacing = 12
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionsStack)

        // --- Центрируем карточки и VS в отдельном контейнере ---
        centerWidgetsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(centerWidgetsContainer)
        NSLayoutConstraint.activate([
            centerWidgetsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerWidgetsContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            centerWidgetsContainer.widthAnchor.constraint(equalToConstant: 400),
            centerWidgetsContainer.heightAnchor.constraint(equalToConstant: 200),
        ])
        // Добавляем карточки и VS внутрь контейнера
        universalPlayerCell.translatesAutoresizingMaskIntoConstraints = false
        vsLabel.translatesAutoresizingMaskIntoConstraints = false
        universalNpcCell.translatesAutoresizingMaskIntoConstraints = false
        centerWidgetsContainer.addSubview(universalPlayerCell)
        centerWidgetsContainer.addSubview(vsLabel)
        centerWidgetsContainer.addSubview(universalNpcCell)

        NSLayoutConstraint.activate([
            // Player слева от центра
            universalPlayerCell.centerYAnchor.constraint(equalTo: centerWidgetsContainer.centerYAnchor, constant: 21),
            universalPlayerCell.trailingAnchor.constraint(equalTo: centerWidgetsContainer.centerXAnchor, constant: -30),
            universalPlayerCell.widthAnchor.constraint(equalToConstant: 140),
            universalPlayerCell.heightAnchor.constraint(equalToConstant: 140),
            
            vsLabel.centerXAnchor.constraint(equalTo: centerWidgetsContainer.centerXAnchor),
            vsLabel.centerYAnchor.constraint(equalTo: centerWidgetsContainer.centerYAnchor, constant: 15),
            
            // NPC справа от центра
            universalNpcCell.centerYAnchor.constraint(equalTo: centerWidgetsContainer.centerYAnchor, constant: 21),
            universalNpcCell.leadingAnchor.constraint(equalTo: centerWidgetsContainer.centerXAnchor, constant: 30),
            universalNpcCell.widthAnchor.constraint(equalToConstant: 140),
            universalNpcCell.heightAnchor.constraint(equalToConstant: 140)
        ])

        // Combat log/result label
        resultLabel.font = UIFont(name: "Optima-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        resultLabel.textColor = .white
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.layer.shadowColor = UIColor.black.cgColor
        resultLabel.layer.shadowOpacity = 0.7
        resultLabel.layer.shadowRadius = 3
        resultLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(resultLabel)

        // Layout
        NSLayoutConstraint.activate([
            witnessWarningLabel.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 16),
            witnessWarningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            witnessWarningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionsStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // --- Combat log ---
            resultLabel.topAnchor.constraint(equalTo: centerWidgetsContainer.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }
    
    private func setupInitialCombatState() {
        guard let player = player else { return }
        CombatService.shared.startCombat(player: player, npc: npc)
        universalPlayerCell.configure(with: player, isDisabled: false)
        universalNpcCell.configure(with: npc, isSelected: true, isDisabled: false)
        // --- Assistants setup ---
        setupAssistantNPCs()
        checkCombatEnd()
    }
    
    private func setupAssistantNPCs() {
        print("[DEBUG] removeFromSuperview for all old assistants")
        for cell in assistantNpcCells { cell.removeFromSuperview() }
        assistantNpcCells.removeAll()
        // Получаем ассистентов, исключая текущего главного NPC
        let assistants = npcAssistants
        let cellSize: CGFloat = 140
        for (i, assistant) in assistants.prefix(3).enumerated() {
            let cell = UniversalCharacterCell(frame: CGRect(x: 0, y: 0, width: cellSize, height: cellSize))
            print("[DEBUG] addSubview assistant cell: \(Unmanaged.passUnretained(cell).toOpaque()) npc: \(assistant.name) id: \(assistant.id)")
            cell.configure(with: assistant, isSelected: false, isDisabled: false)
            print("[DEBUG] configure assistant cell: \(Unmanaged.passUnretained(cell).toOpaque()) npc: \(assistant.name) id: \(assistant.id) isSelected: false")
            cell.translatesAutoresizingMaskIntoConstraints = true
            cell.clipsToBounds = false
            let colors: [UIColor] = [.systemGreen, .systemBlue, .systemOrange]
            // cell.backgroundColor = colors[i % colors.count].withAlphaComponent(0.2)
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleAssistantTap(_:)))
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            cell.tag = i
            view.addSubview(cell)
            assistantNpcCells.append(cell)
        }
        // После создания ассистентов логируем адреса
        print("[DEBUG] universalNpcCell: \(Unmanaged.passUnretained(universalNpcCell).toOpaque())")
        for (i, cell) in assistantNpcCells.enumerated() {
            print("[DEBUG] assistantNpcCell[\(i)]: \(Unmanaged.passUnretained(cell).toOpaque())")
        }
    }
    
    @objc private func handleAssistantTap(_ sender: UITapGestureRecognizer) {
        guard let tappedCell = sender.view as? UniversalCharacterCell,
              let index = assistantNpcCells.firstIndex(of: tappedCell) else { return }
        let assistants = npcAssistants
        guard index < assistants.count else { return }
        let selectedAssistant = assistants[index]
        let oldNpc = self.npc
        self.npc = selectedAssistant
        self.npcManager.selectedNPC = selectedAssistant
        // Удаляем выбранного ассистента из ассистентов
        self.npcAssistants.remove(at: index)
        // Добавляем предыдущего активного NPC в ассистенты, если его там нет
        if !self.npcAssistants.contains(where: { $0.id == oldNpc.id }) {
            self.npcAssistants.append(oldNpc)
        }
        setupAssistantNPCs()
        universalNpcCell.configure(with: self.npc, isSelected: true, isDisabled: false)
        let newAssistants = npcAssistants
        for (i, cell) in assistantNpcCells.enumerated() {
            if i < newAssistants.count {
                cell.configure(with: newAssistants[i], isSelected: false, isDisabled: false)
            }
        }
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
        guard let npcSuperview = universalNpcCell.superview else { return }
        npcSuperview.clipsToBounds = false
        view.clipsToBounds = false
        let cellSize: CGFloat = 140
        let verticalSpacing: CGFloat = -110
        // Получаем frame universalNpcCell относительно view
        let npcCellFrame = npcSuperview.convert(universalNpcCell.frame, to: view)
        let npcRightX = npcCellFrame.maxX
        let npcCenterY = npcCellFrame.midY
        let count = assistantNpcCells.count
        let totalHeight = CGFloat(count) * cellSize + CGFloat(max(count - 1, 0)) * verticalSpacing
        let stackCenterY = npcCenterY
        for (i, cell) in assistantNpcCells.enumerated() {
            cell.clipsToBounds = false
            let x = npcRightX + 32
            let y = stackCenterY - totalHeight/2 + CGFloat(i) * (cellSize + verticalSpacing)
            cell.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
            cell.layer.zPosition = CGFloat(i)
        }
    }
    
    private func setupActionButtons() {
        actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if isCombatEnded {
            if npc.isAlive == false {
                let lootButton = ActionButtonSmallView(title: "Loot", icon: "bag.fill", color: .systemYellow) { [weak self] in
                    self?.openLoot()
                }
                actionsStack.addArrangedSubview(lootButton)
            }
            let leaveButton = ActionButtonSmallView(title: "Leave", icon: "arrowshape.turn.up.left.fill", color: .white) { [weak self] in
                self?.closeCombat()
            }
            actionsStack.addArrangedSubview(leaveButton)
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
            witnessWarningLabel.text = "⚠️ There are witnesses! Vampire actions will have consequences. (\(witnesses))"
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
            actionsStack.addArrangedSubview(button)
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
            resultLabel.attributedText = pretty
        } else {
            resultLabel.text = ""
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
            actionsStack.isUserInteractionEnabled = true
            actionsStack.isHidden = false
            finishButton.isHidden = true
            resultLabel.text = isPlayerDead ? "You died!" : "Enemy defeated!"
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
