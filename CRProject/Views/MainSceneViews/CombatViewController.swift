import UIKit
import SwiftUI

class CombatViewController: UIViewController {
    private let mainViewModel: MainSceneViewModel
    private let npc: NPC
    
    // UI
    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let playerView = CombatParticipantView(alignment: .left)
    private let npcView = CombatParticipantView(alignment: .right)
    private let vsLabel = UILabel()
    private let actionsStack = UIStackView()
    private let resultLabel = UILabel()
    private let finishButton = UIButton(type: .system)
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    
    // State
    private var player: Player? { GameStateService.shared.player }
    private var combatState: CombatState? { CombatService.shared.currentCombatState }
    private var lastActionType: CombatActionType? = nil
    private var isCombatEnded: Bool = false
    
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
        setupBackgroundImage()
        setupTopWidget()
        setupCombatUI()
        setupInitialCombatState()
        finishButton.setTitle("Finish Combat", for: .normal)
        finishButton.titleLabel?.font = UIFont(name: "Optima-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        finishButton.layer.cornerRadius = 12
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.isHidden = true
        finishButton.addTarget(self, action: #selector(closeCombat), for: .touchUpInside)
        view.addSubview(finishButton)
        NSLayoutConstraint.activate([
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            finishButton.widthAnchor.constraint(equalToConstant: 180),
            finishButton.heightAnchor.constraint(equalToConstant: 44)
        ])
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
        overlayView.frame = viewport
        dustEffectView?.view.frame = viewport
        view.sendSubviewToBack(backgroundImageView)
        view.sendSubviewToBack(overlayView)
        if let dustView = dustEffectView?.view {
            view.insertSubview(dustView, aboveSubview: overlayView)
        }
    }
    
    private func setupCombatUI() {
        // Заголовок
        titleLabel.text = "COMBAT"
        titleLabel.font = UIFont(name: "Optima-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Иконка боя
        iconImageView.image = UIImage(systemName: "cross.case.fill")
        iconImageView.tintColor = .systemRed
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconImageView)
        
        // VS label
        vsLabel.text = "VS"
        vsLabel.font = UIFont(name: "Optima-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        vsLabel.textColor = .systemRed
        vsLabel.textAlignment = .center
        vsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vsLabel)
        
        // Участники боя
        playerView.translatesAutoresizingMaskIntoConstraints = false
        npcView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        view.addSubview(npcView)
        
        // Стек кнопок действий
        actionsStack.axis = .horizontal
        actionsStack.spacing = 16
        actionsStack.distribution = .fillEqually
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionsStack)
        
        // Результат действия
        resultLabel.font = UIFont(name: "Optima", size: 15) ?? UIFont.systemFont(ofSize: 15)
        resultLabel.textColor = .white
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            playerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            playerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            playerView.widthAnchor.constraint(equalToConstant: 120),
            playerView.heightAnchor.constraint(equalToConstant: 170),
            
            npcView.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            npcView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            npcView.widthAnchor.constraint(equalToConstant: 120),
            npcView.heightAnchor.constraint(equalToConstant: 170),
            
            vsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vsLabel.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            actionsStack.heightAnchor.constraint(equalToConstant: 48),
            
            resultLabel.bottomAnchor.constraint(equalTo: actionsStack.topAnchor, constant: -16),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }
    
    private func setupInitialCombatState() {
        guard let player = player else { return }
        // Создаём CombatParticipant для игрока и NPC
        let playerParticipant = CombatParticipant(
            id: String(player.id),
            isPlayer: true,
            health: Int(player.bloodMeter.currentBlood),
            blood: Int(player.bloodMeter.currentBlood),
            morale: 0, // Можно доработать если появится поле
            name: player.name,
            profession: player.profession,
            items: player.items.map { $0.id },
            statuses: [],
            relations: [:]
        )
        let npcParticipant = CombatParticipant(
            id: String(npc.id),
            isPlayer: false,
            health: Int(npc.bloodMeter.currentBlood),
            blood: Int(npc.bloodMeter.currentBlood),
            morale: 0, // Можно доработать если появится поле
            name: npc.name,
            profession: npc.profession,
            items: npc.items.map { $0.id },
            statuses: [],
            relations: [:]
        )
        // Инициализируем бой
        CombatService.shared.startCombat(with: [playerParticipant, npcParticipant], type: .duel, initiator: playerParticipant)
        // Отображаем участников
        playerView.configure(with: playerParticipant, isSelected: true, isDisabled: false)
        npcView.configure(with: npcParticipant, isSelected: false, isDisabled: false)
        // Кнопки действий
        setupActionButtons()
    }
    
    private func setupActionButtons() {
        actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let actions: [(String, CombatActionType)] = [
            ("Attack", .attack),
            ("Bite", .bite),
            ("Dominate", .dominate),
            ("Escape", .escape),
            ("Shadowstep", .shadowStep)
        ]
        for (title, type) in actions {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont(name: "Optima-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.darkGray.withAlphaComponent(0.7)
            button.layer.cornerRadius = 10
            button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
            button.tag = type.rawValue
            actionsStack.addArrangedSubview(button)
        }
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        guard let actionType = CombatActionType(rawValue: sender.tag), let player = player else { return }
        lastActionType = actionType
        let action = CombatAction(
            type: actionType,
            initiatorId: String(player.id),
            targetId: String(npc.id),
            parameters: nil
        )
        CombatService.shared.performAction(action)
        updateUIAfterAction()
    }
    
    private func updateUIAfterAction() {
        guard let state = CombatService.shared.currentCombatState else { return }
        // Обновляем результат
        if let summary = state.result?.summary {
            resultLabel.text = summary
                .replacingOccurrences(of: "Успех", with: "Success")
                .replacingOccurrences(of: "Провал", with: "Fail")
                .replacingOccurrences(of: "Завершён", with: "Finished")
                .replacingOccurrences(of: "Критический успех", with: "Critical Success")
                .replacingOccurrences(of: "Критический провал", with: "Critical Fail")
        } else {
            resultLabel.text = ""
        }
        // Получаем актуальные значения здоровья
        var playerHealth = 0
        var npcHealth = 0
        for p in state.participants {
            if p.isPlayer { playerHealth = p.health }
            else { npcHealth = p.health }
        }
        // Обновляем ячейки
        if let playerP = state.participants.first(where: { $0.isPlayer }) {
            playerView.configure(with: playerP, isSelected: true, isDisabled: false)
        }
        if let npcP = state.participants.first(where: { !$0.isPlayer }) {
            npcView.configure(with: npcP, isSelected: false, isDisabled: false)
        }
        // Проверяем завершение боя
        let isPlayerDead = playerHealth <= 0
        let isNpcDead = npcHealth <= 0
        let isEscape = (lastActionType == .escape || lastActionType == .shadowStep) && (state.result?.summary.contains("успех") ?? false)
        if isPlayerDead || isNpcDead || isEscape {
            isCombatEnded = true
            actionsStack.isUserInteractionEnabled = false
            finishButton.isHidden = false
            if isPlayerDead {
                resultLabel.text = "Вы проиграли. Бой завершён."
            } else if isNpcDead {
                resultLabel.text = "Победа! Противник повержен."
            } else if isEscape {
                resultLabel.text = "Вы успешно покинули бой."
            } else {
                resultLabel.text = "Бой завершён."
            }
        }
    }
    
    @objc private func closeCombat() {
        self.dismiss(animated: true, completion: nil)
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
        view.addSubview(overlayView)
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = true
        dustViewHostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(dustViewHostingController)
        view.addSubview(dustViewHostingController.view)
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
    }
} 
