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
    // Кнопки после завершения боя
    private let postCombatStack = UIStackView()
    private let leaveButton = UIButton(type: .system)
    private let lootButton = UIButton(type: .system)
    private let witnessWarningLabel = UILabel()
    
    // State
    private var player: Player? { GameStateService.shared.player }
    private var lastActionType: CombatActionType? = nil
    private var isCombatEnded: Bool = false
    
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
        setupBackgroundImage()
        setupTopWidget()
        setupCombatUI()
        setupInitialCombatState()
        setupActionButtons()
        // --- Кнопки после боя ---
        postCombatStack.axis = .horizontal
        postCombatStack.spacing = 24
        postCombatStack.distribution = .fillEqually
        postCombatStack.translatesAutoresizingMaskIntoConstraints = false
        postCombatStack.isHidden = true
        view.addSubview(postCombatStack)
        NSLayoutConstraint.activate([
            postCombatStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            postCombatStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            postCombatStack.widthAnchor.constraint(equalToConstant: 320),
            postCombatStack.heightAnchor.constraint(equalToConstant: 48)
        ])
        // Leave
        leaveButton.setTitle("Leave", for: .normal)
        leaveButton.titleLabel?.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18)
        leaveButton.setTitleColor(.white, for: .normal)
        leaveButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        leaveButton.layer.cornerRadius = 12
        leaveButton.layer.shadowColor = UIColor.black.cgColor
        leaveButton.layer.shadowOpacity = 0.7
        leaveButton.layer.shadowRadius = 3
        leaveButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        leaveButton.addTarget(self, action: #selector(closeCombat), for: .touchUpInside)
        postCombatStack.addArrangedSubview(leaveButton)
        // Loot
        lootButton.setTitle("Loot", for: .normal)
        lootButton.titleLabel?.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18)
        lootButton.setTitleColor(.white, for: .normal)
        lootButton.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.8)
        lootButton.layer.cornerRadius = 12
        lootButton.layer.shadowColor = UIColor.black.cgColor
        lootButton.layer.shadowOpacity = 0.7
        lootButton.layer.shadowRadius = 3
        lootButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        lootButton.addTarget(self, action: #selector(openLoot), for: .touchUpInside)
        postCombatStack.addArrangedSubview(lootButton)
        finishButton.setTitle("Finish Combat", for: .normal)
        finishButton.titleLabel?.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18)
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
            vsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerView.centerYAnchor.constraint(equalTo: vsLabel.centerYAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            playerView.widthAnchor.constraint(equalToConstant: 120),
            playerView.heightAnchor.constraint(equalToConstant: 170),
            npcView.centerYAnchor.constraint(equalTo: vsLabel.centerYAnchor),
            npcView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            npcView.widthAnchor.constraint(equalToConstant: 120),
            npcView.heightAnchor.constraint(equalToConstant: 170),
            resultLabel.bottomAnchor.constraint(equalTo: actionsStack.topAnchor, constant: -12),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    private func setupInitialCombatState() {
        guard let player = player else { return }
        CombatService.shared.startCombat(player: player, npc: npc)
        playerView.configure(with: player, isSelected: true, isDisabled: false)
        npcView.configure(with: npc, isSelected: false, isDisabled: false)
        checkCombatEnd()
    }
    
    private func setupActionButtons() {
        actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var actions: [CombatActionType] = [.attack, .feed, .drain]
        if AbilitiesSystem.shared.hasDomination {
            actions.insert(.dominate, at: 2)
        }
        let witnesses = GameStateService.shared.getAwakeNpcsCount()
        let hasVampireAction = actions.contains(where: { $0 == .feed || $0 == .drain || $0 == .dominate })
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
        for type in actions {
            let button = UIButton(type: .system)
            // Получаем шанс успеха
            let chance = CombatService.shared.getBaseChance(for: type)
            let chancePercent = Int(chance * 100)
            // Атмосферные описания последствий
            let consequenceDescription: String = {
                switch type {
                case .attack:
                    return "Success: Wound your foe: -25 HP to enemy\nFail: You are struck back: -25 HP to you"
                case .feed:
                    return "Success: Sink your fangs: +25 HP to you, -25 HP to enemy\nFail: You are repelled: -25 HP to you"
                case .drain:
                    return "Success: Devour completely: Enemy dies, you absorb all their blood\nFail: You are wounded: -25 HP to you"
                case .dominate:
                    return "Dominate (no damage)"
                default:
                    return type.consequenceDescription
                }
            }()
            // Цвета для действий
            let (titleColor, iconColor): (UIColor, UIColor) = {
                switch type {
                case .attack: return (.systemOrange, .systemOrange)
                case .feed: return (.systemPink, .systemPink)
                case .dominate: return (.systemBlue, .systemBlue)
                case .drain: return (.systemRed, .systemRed)
                default: return (.white, .white)
                }
            }()
            // --- Новый стиль: иконка в первой строке через NSTextAttachment ---
            let iconAttachment = NSTextAttachment()
            if let iconImage = UIImage(systemName: type.icon)?.withRenderingMode(.alwaysTemplate) {
                let iconSize: CGFloat = 18
                UIGraphicsBeginImageContextWithOptions(CGSize(width: iconSize, height: iconSize), false, 0.0)
                iconImage.withTintColor(iconColor).draw(in: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                let resizedIcon = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                iconAttachment.image = resizedIcon
                iconAttachment.bounds = CGRect(x: 0, y: -2, width: iconSize, height: iconSize)
            }
            let iconString = NSAttributedString(attachment: iconAttachment)
            // --- paragraph style для переноса строк ---
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .center
            // Success и Fail разными цветами и с маленькими иконками
            let consequenceLines = consequenceDescription.components(separatedBy: "\n")
            let successLine = consequenceLines.first ?? ""
            let failLine = consequenceLines.count > 1 ? consequenceLines[1] : ""
            let successAttr = NSAttributedString(string: successLine.isEmpty ? "" : "\u{2713} " + successLine + "\n", attributes: [
                .font: UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(red: 0.66, green: 1.0, blue: 0.69, alpha: 1.0), // #A8FFB0
                .paragraphStyle: paragraphStyle
            ])
            let failAttr = NSAttributedString(string: failLine.isEmpty ? "" : "\u{2717} " + failLine, attributes: [
                .font: UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0), // #FF6B6B
                .paragraphStyle: paragraphStyle
            ])
            let firstLine = NSMutableAttributedString()
            firstLine.append(iconString)
            firstLine.append(NSAttributedString(string: " \(type.displayName) \(chancePercent)%\n\n", attributes: [
                .font: UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14),
                .foregroundColor: titleColor,
                .paragraphStyle: paragraphStyle
            ]))
            let attrTitle = NSMutableAttributedString()
            attrTitle.append(firstLine)
            attrTitle.append(successAttr)
            attrTitle.append(failAttr)
            button.setAttributedTitle(attrTitle, for: .normal)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            // --- Стилизация кнопки ---
            button.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 0.92) // #23232A
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 2
            // Менее насыщенная рамка
            button.layer.borderColor = iconColor.withAlphaComponent(0.5).cgColor
            // Внутреннее свечение (glow)
            let glow = CALayer()
            glow.frame = button.bounds.insetBy(dx: 4, dy: 4)
            glow.cornerRadius = 8
            glow.backgroundColor = iconColor.withAlphaComponent(0.18).cgColor
            glow.shadowColor = iconColor.cgColor
            glow.shadowRadius = 8
            glow.shadowOpacity = 0.5
            glow.shadowOffset = .zero
            button.layer.insertSublayer(glow, at: 1)
            // Внутренняя тень (inner shadow)
            let innerShadow = CALayer()
            innerShadow.frame = button.bounds
            innerShadow.cornerRadius = 10
            innerShadow.backgroundColor = UIColor.clear.cgColor
            innerShadow.shadowColor = UIColor.black.cgColor
            innerShadow.shadowOffset = CGSize(width: 0, height: 2)
            innerShadow.shadowOpacity = 0.25
            innerShadow.shadowRadius = 6
            button.layer.insertSublayer(innerShadow, at: 2)
            // Ограничение максимальной и минимальной высоты кнопки
            button.heightAnchor.constraint(lessThanOrEqualToConstant: 155).isActive = true
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 90).isActive = true
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            // Добавляем тень к тексту на кнопке
            button.titleLabel?.layer.shadowColor = UIColor.black.cgColor
            button.titleLabel?.layer.shadowOpacity = 0.7
            button.titleLabel?.layer.shadowRadius = 3
            button.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
            button.tag = type.rawValue
            actionsStack.addArrangedSubview(button)
        }
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        guard let actionType = CombatActionType(rawValue: sender.tag) else { return }
        lastActionType = actionType
        let action = CombatAction(type: actionType, initiatorId: "", targetId: "", parameters: nil)
        CombatService.shared.performAction(action)
        updateUIAfterAction()
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
            text = isSuccess ? "You hit the enemy!" : "Missed! Enemy strikes back!"
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
            text = "Enemy is dominated!"
            color = UIColor.systemBlue
            icon = "👁️"
        case let s where s.contains("no_effect"):
            text = "No effect."
            color = UIColor.systemGray
            icon = "—"
        case let s where s.contains("target_drained"):
            text = "You drain all blood!"
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
            playerView.configure(with: player, isSelected: true, isDisabled: false)
        }
        npcView.configure(with: npc, isSelected: false, isDisabled: false)
        checkCombatEnd()
        setupActionButtons()
    }
    
    private func checkCombatEnd() {
        guard let player = player else { return }
        let isPlayerDead = !player.isAlive
        let isNpcDead = !npc.isAlive
        if isPlayerDead || isNpcDead {
            isCombatEnded = true
            actionsStack.isUserInteractionEnabled = false
            actionsStack.isHidden = true
            finishButton.isHidden = true
            postCombatStack.isHidden = false
            resultLabel.text = isPlayerDead ? "You died!" : "Enemy defeated!"
        }
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
