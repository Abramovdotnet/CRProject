import UIKit
import SwiftUI
import Combine

struct DialogueItem {
    let text: String
    let type: DialogueOptionType
    let isNPC: Bool
    let npc: NPC?
}

class DialogueTableViewCell: UITableViewCell {
    private let bubbleView = UIView()
    private let stackView = UIStackView()
    private let characterImageView = UIImageView()
    private let nameLabel = UILabel()
    private let dialogueTextLabel = UILabel()
    private let iconImageView = UIImageView()
    
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
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        bubbleView.layer.cornerRadius = 12
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 8
        
        characterImageView.translatesAutoresizingMaskIntoConstraints = false
        characterImageView.contentMode = .scaleAspectFill
        characterImageView.clipsToBounds = true
        characterImageView.layer.cornerRadius = 8
        
        let textStackView = UIStackView()
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.axis = .vertical
        textStackView.spacing = 3
        
        nameLabel.font = UIFont(name: "Optima-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
        nameLabel.textColor = UIColor(Theme.textColor)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        dialogueTextLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        dialogueTextLabel.textColor = UIColor(Theme.textColor)
        dialogueTextLabel.numberOfLines = 0
        dialogueTextLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true // Hide by default
        iconImageView.setContentHuggingPriority(UILayoutPriority(252), for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(UILayoutPriority(752), for: .horizontal)
        
        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(dialogueTextLabel)
        
        stackView.addArrangedSubview(characterImageView)
        stackView.addArrangedSubview(textStackView)
        stackView.addArrangedSubview(iconImageView)
        
        bubbleView.addSubview(stackView)
        contentView.addSubview(bubbleView)
        
        NSLayoutConstraint.activate([
            characterImageView.widthAnchor.constraint(equalToConstant: 30),
            characterImageView.heightAnchor.constraint(equalToConstant: 30),
            
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            stackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
            
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        // Add width constraints with priorities to avoid conflicts during table view sizing
        let widthConstraint = bubbleView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.95)
        widthConstraint.priority = UILayoutPriority(999) // High but not required
        widthConstraint.isActive = true
        
        // Add minimum width constraint as fallback
        let minWidthConstraint = bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        minWidthConstraint.priority = UILayoutPriority(1000) // Required
        minWidthConstraint.isActive = true
        
        // Add maximum width constraint to prevent excessive width
        let maxWidthConstraint = bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 600)
        maxWidthConstraint.priority = UILayoutPriority(1000) // Required
        maxWidthConstraint.isActive = true
    }
    
    func configure(with item: DialogueItem) {
        dialogueTextLabel.text = item.text
        
        if item.isNPC {
            nameLabel.text = "\(item.npc?.name ?? "NPC"):"
            if let npc = item.npc {
                characterImageView.image = UIImage(named: "npc\(npc.id.description)") ?? 
                                         UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!
            }
            // NPC messages don't have interaction icons
            iconImageView.isHidden = true
        } else {
            nameLabel.text = "\(GameStateService.shared.player?.name ?? "Player"):"
            characterImageView.image = UIImage(named: "player1")
            
            // Show interaction icon for player options based on type
            if item.type != .normal {
                iconImageView.isHidden = false
                iconImageView.image = getInteractionIcon(for: item.type)
                iconImageView.tintColor = getIconColor(for: item.type)
            } else {
                iconImageView.isHidden = true
            }
        }
    }
    
    private func getInteractionIcon(for type: DialogueOptionType) -> UIImage? {
        switch type {
        case .persuasion:
            return UIImage(systemName: "exclamationmark.triangle")
        case .normal:
            return UIImage(systemName: "message.fill")
        case .relationshipIncrease:
            return UIImage(systemName: "arrow.up.heart.fill")
        case .relationshipDecrease:
            return UIImage(systemName: "arrow.down.heart.fill")
        }
    }
    
    private func getIconColor(for type: DialogueOptionType) -> UIColor {
        switch type {
        case .persuasion:
            return .red
        case .normal:
            return .white
        case .relationshipIncrease:
            return .green
        case .relationshipDecrease:
            return .red
        }
    }
}

class DialogueViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: DialogueViewModel
    private let mainViewModel: MainSceneViewModel
    private let isSkipable: Bool
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let backgroundImageView = UIImageView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    // Main layout
    private let dialogueTableView = UITableView()
    private let playerWidgetContainer = UIView()
    private let npcWidgetContainer = UIView()
    private var playerWidgetHostingController: UIHostingController<PlayerWidget>?
    private var npcWidgetHostingController: UIHostingController<NPCWidget>?
    
    // Gradient fade overlays
    private let topGradientView = UIView()
    private let bottomGradientView = UIView()
    
    // Current dialogue data
    private var dialogueItems: [DialogueItem] = []
    
    // Action result overlay
    private let actionResultView = UIView()
    private let actionResultLabel = UILabel()
    
    // Love scene overlay
    private var loveSceneHostingController: UIHostingController<LoveScene>?
    
    // Animation properties
    private var contentOpacity: CGFloat = 0.0
    private var isDraggingDialogues = false
    
    // MARK: - Initialization
    init(viewModel: DialogueViewModel, mainViewModel: MainSceneViewModel, isSkipable: Bool = true) {
        self.viewModel = viewModel
        self.mainViewModel = mainViewModel
        self.isSkipable = isSkipable
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
        setupGradientFades()
        setupActionResultView()
        setupBindings()
        
        // Initial animation
        animateAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Background и dust effect теперь управляются constraints - никаких костылей не нужно
        
        // Setup gradient layers for fade effects
        // Only if content is already loaded
        if !dialogueItems.isEmpty {
            DispatchQueue.main.async {
                self.updateGradientFadeVisibility()
            }
        }
    }
    
    private func setupGradientLayers() {
        // Only setup gradients for visible gradient views
        if !topGradientView.isHidden && topGradientView.bounds.width > 0 {
            setupTopGradient()
        }
        
        if !bottomGradientView.isHidden && bottomGradientView.bounds.width > 0 {
            setupBottomGradient()
        }
    }
    
    private func setupTopGradient() {
        // Clear existing content
        topGradientView.subviews.forEach { $0.removeFromSuperview() }
        topGradientView.layer.mask = nil
        
        // Create background image view
        let backgroundImageView = UIImageView(image: backgroundImageView.image)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        
        // Position to match main background
        let gradientPositionInMain = topGradientView.convert(topGradientView.bounds, to: view)
        let mainBackgroundFrame = self.backgroundImageView.frame
        backgroundImageView.frame = CGRect(
            x: -gradientPositionInMain.origin.x + mainBackgroundFrame.origin.x,
            y: -gradientPositionInMain.origin.y + mainBackgroundFrame.origin.y,
            width: mainBackgroundFrame.width,
            height: mainBackgroundFrame.height
        )
        topGradientView.addSubview(backgroundImageView)
        
        // Create gradient mask
        let gradient = CAGradientLayer()
        gradient.frame = topGradientView.bounds
        gradient.colors = [
            UIColor.black.cgColor,    // Solid at top
            UIColor.clear.cgColor     // Transparent at bottom
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        topGradientView.layer.mask = gradient
    }
    
    private func setupBottomGradient() {
        // Clear existing content
        bottomGradientView.subviews.forEach { $0.removeFromSuperview() }
        bottomGradientView.layer.mask = nil
        
        // Create background image view
        let backgroundImageView = UIImageView(image: backgroundImageView.image)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        
        // Position to match main background
        let gradientPositionInMain = bottomGradientView.convert(bottomGradientView.bounds, to: view)
        let mainBackgroundFrame = self.backgroundImageView.frame
        backgroundImageView.frame = CGRect(
            x: -gradientPositionInMain.origin.x + mainBackgroundFrame.origin.x,
            y: -gradientPositionInMain.origin.y + mainBackgroundFrame.origin.y,
            width: mainBackgroundFrame.width,
            height: mainBackgroundFrame.height
        )
        bottomGradientView.addSubview(backgroundImageView)
        
        // Create gradient mask
        let gradient = CAGradientLayer()
        gradient.frame = bottomGradientView.bounds
        gradient.colors = [
            UIColor.clear.cgColor,    // Transparent at top
            UIColor.black.cgColor     // Solid at bottom
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        bottomGradientView.layer.mask = gradient
    }
    
    // MARK: - Setup Methods
    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let currentScene = GameStateService.shared.currentScene {
            let imageName = "location\(currentScene.id)"
            backgroundImageView.image = UIImage(named: imageName) ?? UIImage(named: "MainSceneBackground")!
        } else {
            backgroundImageView.image = UIImage(named: "MainSceneBackground")!
        }
        
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
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        NSLayoutConstraint.activate([
            widgetVC.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor),
            widgetVC.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor),
            widgetVC.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor),
            widgetVC.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor)
        ])
    }
    
    private func setupMainLayout() {
        // Create main horizontal stack view
        let mainStackView = UIStackView()
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .horizontal
        mainStackView.alignment = .top
        mainStackView.distribution = .fill
        mainStackView.spacing = 0
        view.addSubview(mainStackView)
        
        // Player widget (left side)
        setupPlayerWidget()
        mainStackView.addArrangedSubview(playerWidgetContainer)
        
        // Spacer
        let leftSpacer = UIView()
        leftSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        mainStackView.addArrangedSubview(leftSpacer)
        
        // Dialogue scroll view (center)
        setupDialogueTableView()
        mainStackView.addArrangedSubview(dialogueTableView)
        
        // Spacer
        let rightSpacer = UIView()
        rightSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        mainStackView.addArrangedSubview(rightSpacer)
        
        // NPC widget (right side)
        setupNPCWidget()
        mainStackView.addArrangedSubview(npcWidgetContainer)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        // Widget constraints
        NSLayoutConstraint.activate([
            playerWidgetContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.23),
            npcWidgetContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.23),
            dialogueTableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor),
            
            // Возвращаем height constraint для видимости опций
            dialogueTableView.heightAnchor.constraint(equalTo: mainStackView.heightAnchor)
        ])
    }
    
    private func setupPlayerWidget() {
        playerWidgetContainer.translatesAutoresizingMaskIntoConstraints = false
        
        guard let player = GameStateService.shared.player else { return }
        
        let playerWidget = PlayerWidget(player: player)
        let hostingController = UIHostingController(rootView: playerWidget)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        playerWidgetContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: playerWidgetContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: playerWidgetContainer.leadingAnchor, constant: 16),
            hostingController.view.trailingAnchor.constraint(equalTo: playerWidgetContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(lessThanOrEqualTo: playerWidgetContainer.bottomAnchor)
        ])
        
        self.playerWidgetHostingController = hostingController
    }
    
    private func setupNPCWidget() {
        npcWidgetContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let npcWidget = NPCWidget(
            npc: viewModel.npc,
            isSelected: false,
            isDisabled: false,
            showCurrentActivity: false,
            onTap: { },
            onAction: { _ in }
        )
        let hostingController = UIHostingController(rootView: npcWidget)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        npcWidgetContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: npcWidgetContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: npcWidgetContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: npcWidgetContainer.trailingAnchor, constant: -16),
            hostingController.view.bottomAnchor.constraint(lessThanOrEqualTo: npcWidgetContainer.bottomAnchor)
        ])
        
        self.npcWidgetHostingController = hostingController
    }
    
    private func setupDialogueTableView() {
        dialogueTableView.translatesAutoresizingMaskIntoConstraints = false
        dialogueTableView.backgroundColor = .clear
        dialogueTableView.showsVerticalScrollIndicator = false
        dialogueTableView.showsHorizontalScrollIndicator = false
        
        // Configure for dynamic cell heights
        dialogueTableView.rowHeight = UITableView.automaticDimension
        dialogueTableView.estimatedRowHeight = 80
        dialogueTableView.separatorStyle = .none
        
        dialogueTableView.dataSource = self
        dialogueTableView.delegate = self
        
        dialogueTableView.register(DialogueTableViewCell.self, forCellReuseIdentifier: "DialogueTableViewCell")
    }
    
    private func setupActionResultView() {
        actionResultView.translatesAutoresizingMaskIntoConstraints = false
        actionResultView.backgroundColor = UIColor(Theme.secondaryColor).withAlphaComponent(0.9)
        actionResultView.layer.cornerRadius = 12
        actionResultView.layer.shadowColor = UIColor.black.cgColor
        actionResultView.layer.shadowRadius = 5
        actionResultView.layer.shadowOpacity = 0.3
        actionResultView.layer.shadowOffset = CGSize(width: 0, height: 2)
        actionResultView.isHidden = true
        view.addSubview(actionResultView)
        
        actionResultLabel.translatesAutoresizingMaskIntoConstraints = false
        actionResultLabel.font = UIFont(name: "Optima-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18)
        actionResultLabel.textAlignment = .center
        actionResultLabel.numberOfLines = 0
        actionResultView.addSubview(actionResultLabel)
        
        NSLayoutConstraint.activate([
            actionResultView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionResultView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 50),
            actionResultView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            actionResultView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            actionResultLabel.topAnchor.constraint(equalTo: actionResultView.topAnchor, constant: 16),
            actionResultLabel.leadingAnchor.constraint(equalTo: actionResultView.leadingAnchor, constant: 16),
            actionResultLabel.trailingAnchor.constraint(equalTo: actionResultView.trailingAnchor, constant: -16),
            actionResultLabel.bottomAnchor.constraint(equalTo: actionResultView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupGradientFades() {
        // Setup top gradient overlay
        topGradientView.translatesAutoresizingMaskIntoConstraints = false
        topGradientView.isUserInteractionEnabled = false
        topGradientView.backgroundColor = .clear
        view.addSubview(topGradientView)
        
        // Setup bottom gradient overlay
        bottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        bottomGradientView.isUserInteractionEnabled = false
        bottomGradientView.backgroundColor = .clear
        view.addSubview(bottomGradientView)
        
        // Position overlays over the dialogue table view
        NSLayoutConstraint.activate([
            // Top gradient overlay
            topGradientView.topAnchor.constraint(equalTo: dialogueTableView.topAnchor),
            topGradientView.leadingAnchor.constraint(equalTo: dialogueTableView.leadingAnchor),
            topGradientView.trailingAnchor.constraint(equalTo: dialogueTableView.trailingAnchor),
            topGradientView.heightAnchor.constraint(equalToConstant: 40),
            
            // Bottom gradient overlay
            bottomGradientView.bottomAnchor.constraint(equalTo: dialogueTableView.bottomAnchor),
            bottomGradientView.leadingAnchor.constraint(equalTo: dialogueTableView.leadingAnchor),
            bottomGradientView.trailingAnchor.constraint(equalTo: dialogueTableView.trailingAnchor),
            bottomGradientView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Start with gradients hidden - they will appear dynamically during scroll
        topGradientView.isHidden = true
        topGradientView.alpha = 0
        bottomGradientView.isHidden = true
        bottomGradientView.alpha = 0
        
        // Bring overlays to front
        view.bringSubviewToFront(topGradientView)
        view.bringSubviewToFront(bottomGradientView)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Listen to dialogue text changes
        viewModel.$currentDialogueText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.updateDialogueContent()
            }
            .store(in: &cancellables)
        
        // Listen to options changes
        viewModel.$options
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDialogueContent()
            }
            .store(in: &cancellables)
        
        // Listen to action result changes
        viewModel.$showActionResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.updateActionResult()
            }
            .store(in: &cancellables)
        
        // Listen to love scene changes
        viewModel.$showLoveScene
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.updateLoveScene()
            }
            .store(in: &cancellables)
        
        // Listen to dismiss changes
        viewModel.$shouldDismiss
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldDismiss in
                DebugLogService.shared.log("🚪 DialogueViewController: shouldDismiss changed to: \(shouldDismiss)", category: "DialogueVC")
                // Note: Dismissal is now handled by DialogueViewControllerWrapper
                // if shouldDismiss {
                //     DebugLogService.shared.log("🚪 DialogueViewController: Calling dismiss(animated: true)", category: "DialogueVC")
                //     self?.dismiss(animated: true)
                // }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    private func updateDialogueContent() {
        // Create dialogue items array
        dialogueItems.removeAll()
        
        // Add NPC text bubble if not empty
        if !viewModel.currentDialogueText.isEmpty {
            dialogueItems.append(DialogueItem(text: viewModel.currentDialogueText, type: .normal, isNPC: true, npc: viewModel.npc))
        }
        
        // Add player options
        for option in viewModel.options {
            dialogueItems.append(DialogueItem(text: option.text, type: option.type, isNPC: false, npc: nil))
        }
        
        // Reload table with animation
        UIView.transition(with: dialogueTableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.dialogueTableView.reloadData()
        }, completion: { _ in
            // Update gradient fade visibility after reload completes
            DispatchQueue.main.async {
                self.updateGradientFadeVisibility()
            }
        })
    }
    
    private func updateGradientFadeVisibility() {
        let contentHeight = dialogueTableView.contentSize.height
        let visibleHeight = dialogueTableView.bounds.height
        let contentOffset = dialogueTableView.contentOffset.y
        
        // Check if content can scroll
        let canScroll = contentHeight > visibleHeight
        
        // Check if there's content above current visible area
        let hasContentAbove = contentOffset > 0
        
        // Check if there's content below current visible area  
        let hasContentBelow = contentOffset + visibleHeight < contentHeight
        
        if canScroll {
            // Show/hide top gradient based on scroll position
            if hasContentAbove {
                topGradientView.isHidden = false
                topGradientView.alpha = min(1.0, contentOffset / 20.0) // Fade in gradually
            } else {
                topGradientView.isHidden = true
                topGradientView.alpha = 0
            }
            
            // Show/hide bottom gradient based on scroll position
            if hasContentBelow {
                bottomGradientView.isHidden = false
                let remainingContent = contentHeight - (contentOffset + visibleHeight)
                bottomGradientView.alpha = min(1.0, remainingContent / 20.0) // Fade in gradually
            } else {
                bottomGradientView.isHidden = true
                bottomGradientView.alpha = 0
            }
            
            // Setup gradients if any are visible
            if !topGradientView.isHidden || !bottomGradientView.isHidden {
                setupGradientLayers()
            }
        } else {
            // Hide all gradients when content fits entirely
            topGradientView.isHidden = true
            bottomGradientView.isHidden = true
        }
    }
    
    private func updateActionResult() {
        if viewModel.showActionResult {
            actionResultLabel.text = viewModel.actionResultMessage
            actionResultLabel.textColor = viewModel.actionResultSuccess ? .green : .red
            
            actionResultView.isHidden = false
            actionResultView.alpha = 0
            actionResultView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.actionResultView.alpha = 1
                self.actionResultView.transform = .identity
            }) { _ in
                // Auto-hide after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    UIView.animate(withDuration: 0.3) {
                        self.actionResultView.alpha = 0
                        self.actionResultView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    } completion: { _ in
                        self.actionResultView.isHidden = true
                    }
                }
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.actionResultView.alpha = 0
            } completion: { _ in
                self.actionResultView.isHidden = true
            }
        }
    }
    
    private func updateLoveScene() {
        if viewModel.showLoveScene {
            let loveScene = LoveScene()
            let hostingController = UIHostingController(rootView: loveScene)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.backgroundColor = .clear
            
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            // Hide top widget
            topWidgetContainerView.alpha = 0
            
            // Animate love scene appearance
            hostingController.view.alpha = 0
            hostingController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.5) {
                hostingController.view.alpha = 1
                hostingController.view.transform = .identity
            }
            
            self.loveSceneHostingController = hostingController
        } else {
            // Show top widget
            topWidgetContainerView.alpha = 1
            
            // Remove love scene
            if let loveSceneController = loveSceneHostingController {
                UIView.animate(withDuration: 0.5, animations: {
                    loveSceneController.view.alpha = 0
                    loveSceneController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }) { _ in
                    loveSceneController.willMove(toParent: nil)
                    loveSceneController.view.removeFromSuperview()
                    loveSceneController.removeFromParent()
                }
                self.loveSceneHostingController = nil
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            isDraggingDialogues = true
        case .ended, .cancelled:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isDraggingDialogues = false
            }
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    private func getNPCImage(npc: NPC) -> UIImage {
        return UIImage(named: "npc\(npc.id.description)") ?? 
               UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!
    }
    
    private func animateAppearance() {
        view.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1
        }
        
        UIView.animate(withDuration: 0.4, delay: 0.3) {
            self.contentOpacity = 1
            self.dialogueTableView.alpha = 1
        }
    }
    
    // MARK: - Dismissal
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Check if dismissal is allowed
        if !isSkipable && !viewModel.shouldDismiss {
            // Prevent dismissal if not skipable and viewModel doesn't allow it
            // This might need additional logic depending on your navigation setup
        }
    }
}

extension DialogueViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dialogueItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DialogueTableViewCell", for: indexPath) as! DialogueTableViewCell
        let dialogueItem = dialogueItems[indexPath.row]
        cell.configure(with: dialogueItem)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isDraggingDialogues { return }
        
        let dialogueItem = dialogueItems[indexPath.row]
        
        // Only allow selecting player options, not NPC text
        if !dialogueItem.isNPC {
            // Find the corresponding option in the viewModel
            if let option = viewModel.options.first(where: { $0.text == dialogueItem.text }) {
                viewModel.selectOption(option)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Update gradients dynamically as user scrolls
        updateGradientFadeVisibility()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Final update when scrolling stops
        updateGradientFadeVisibility()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // Update immediately if not decelerating
            updateGradientFadeVisibility()
        }
    }
} 