import UIKit
import SwiftUI
import Combine

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case navigation
    case dialogue
    case vampireGaze
    case trade
    case inventory
    case smithing
    case abilities
    case loot
    case questJournal
    case hidingCell
    case combat
}

// MARK: - Custom NPCSGridView with double tap support
class CustomNPCSGridView: NPCSGridView {
    private let onDoubleTap: (NPC) -> Void
    private var lastTapTimes: [Int: Date] = [:]
    
    init(npcs: [NPC],
         npcManager: NPCInteractionManager = .shared,
         gameStateService: GameStateService = DependencyManager.shared.resolve(),
         onAction: @escaping (NPCAction) -> Void,
         onDoubleTap: @escaping (NPC) -> Void) {
        self.onDoubleTap = onDoubleTap
        self.onActionHandler = onAction
        super.init(npcs: npcs, npcManager: npcManager, gameStateService: gameStateService, onAction: onAction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sortedNPCs = prepareNPCData()
        
        guard indexPath.item < sortedNPCs.count else {
            return
        }
        
        let npc = sortedNPCs[indexPath.item]
        handleCustomTap(on: npc)
    }
    
    private func handleCustomTap(on npc: NPC) {
        // Defensive programming: validate NPC object integrity
        guard !npc.name.isEmpty,
              npc.id > 0 else {
            print("Error: Invalid NPC object detected in handleCustomTap")
            return
        }
        
        let currentTime = Date()
        if let lastTapTime = lastTapTimes[npc.id], currentTime.timeIntervalSince(lastTapTime) < 0.3 {
            // Double tap detected - show NPC widget and trigger investigate action
            print("Double tap detected on NPC: \(npc.name)")
            onDoubleTap(npc)
            // Also call the original onAction for investigate (like the parent class does)
            if let onAction = getOnAction() {
                print("Calling onAction(.investigate) for NPC: \(npc.name)")
                // Ensure we're on main thread for UI operations
                DispatchQueue.main.async {
                    onAction(.investigate(npc))
                }
            }
            lastTapTimes[npc.id] = nil
        } else {
            // Single tap - update selection (same as parent class behavior)
            print("Single tap on NPC: \(npc.name)")
            
            // Ensure NPC manager operations happen on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                let oldSelectedNPC = self.npcManager.selectedNPC
                self.npcManager.select(with: npc)
                
                // Update cells for both the previously selected NPC and newly selected NPC
                if let oldNPC = oldSelectedNPC {
                    self.updateNPCCell(for: oldNPC)
                }
                self.updateNPCCell(for: npc)
                
                self.lastTapTimes[npc.id] = currentTime
            }
        }
    }
    
    // Helper method to access the parent's onAction closure
    private func getOnAction() -> ((NPCAction) -> Void)? {
        return self.onActionHandler
    }
    
    private var onActionHandler: ((NPCAction) -> Void)?
}

class SceneViewController: UIViewController {
    private let mainViewModel: MainSceneViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Navigation
    weak var customNavigationController: UINavigationController?
    private var activeDialogueViewModel: DialogueViewModel?
    
    // Top widget
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    // Bottom widget
    private let bottomWidgetContainerView = UIView()
    private var bottomWidgetViewController: BottomWidgetUIViewController?
    
    // Dust effect
    private var dustEffectView: UIHostingController<DustEmitterView>?
    
    // Button stacks
    private let leftButtonStackView = UIStackView() // New left stack for former right buttons
    private let chatButtonsStackView = UIStackView() // Horizontal stack under chat
    
    // NPCs Grid View
    private let npcsGridContainerView = UIView()
    private var npcsGridView: NPCSGridView?
    
    // Selected NPC Info
    private let selectedNPCInfoView = InfoPresentationLabelView()
    
    // NPC Widget Overlay
    private let npcWidgetOverlayView = UIView()
    private var npcWidgetViewController: UIHostingController<NPCWidget>?
    private var isNPCWidgetVisible = false
    
    // Chat container
    private let chatContainerView = UIView()
    private var chatViewController: ChatViewController?
    
    private var chatContainerHeightConstraint: NSLayoutConstraint?
    
    init(mainViewModel: MainSceneViewModel) {
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Observers
    
    private func setupObservers() {
        // Subscribe to NPCs array changes
        mainViewModel.$npcs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newNPCs in
                self?.updateNPCsList(with: newNPCs)
            }
            .store(in: &cancellables)
        
        // Subscribe to UI update triggers from viewModel
        mainViewModel.$shouldUpdateButtons
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonStacks()
            }
            .store(in: &cancellables)
        
        // Subscribe to scene changes
        mainViewModel.$currentScene
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonStacks()
                self?.updateBackground()
            }
            .store(in: &cancellables)
        
        // Subscribe to notification for character changes in scene
        NotificationCenter.default.publisher(for: .sceneCharactersChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let scene = notification.object as? Scene,
                      scene.id == self?.mainViewModel.currentScene?.id else { return }
                let characters = scene.getCharacters()
                let npcs = characters.compactMap { $0 as? NPC }
                self?.updateNPCsList(with: npcs)
            }
            .store(in: &cancellables)
        
        // Subscribe to selected NPC changes
        NPCInteractionManager.shared.$selectedNPC
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedNPC in
                self?.updateSelectedNPCInfo()
                self?.updateChatContainerHeight()
            }
            .store(in: &cancellables)
    }
    
    private func updateNPCsList(with newNPCs: [NPC]) {
        // Remove existing grid view with animation
        let oldGrid = npcsGridView
        let gridView = CustomNPCSGridView(
            npcs: newNPCs,
            npcManager: .shared,
            gameStateService: DependencyManager.shared.resolve(),
            onAction: mainViewModel.handleNPCAction,
            onDoubleTap: { [weak self] npc in
                self?.showNPCWidget(for: npc)
            }
        )
        gridView.translatesAutoresizingMaskIntoConstraints = false

        UIView.transition(with: npcsGridContainerView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            oldGrid?.removeFromSuperview()
            self.npcsGridContainerView.addSubview(gridView)
        }, completion: nil)

        self.npcsGridView = gridView

        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: npcsGridContainerView.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: npcsGridContainerView.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: npcsGridContainerView.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: npcsGridContainerView.bottomAnchor)
        ])
    }
    
    private func updateBackground() {
        // Update background image when scene changes
        guard let backgroundImageView = view.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        
        let imageName = "location\(mainViewModel.currentScene?.id.description ?? "")"
        backgroundImageView.image = UIImage(named: imageName) ?? UIImage(named: "MainSceneBackground")
    }
    
    private func updateSelectedNPCInfo() {
        let selectedNPC = NPCInteractionManager.shared.selectedNPC
        
        if let npc = selectedNPC {
            print("SceneView: Updating info for selected NPC: \(npc.name) (ID: \(npc.id))")
            
            // Configure info view with profession icon, name, and activity icon
            selectedNPCInfoView.configureWithNPCInfo(npc: npc, textColor: UIColor(Theme.textColor))
            
            selectedNPCInfoView.isHidden = false
            print("SceneView: NPC info view shown with profession and activity icons")
        } else {
            print("SceneView: No NPC selected, hiding info view")
            selectedNPCInfoView.isHidden = true
        }
    }
    
    // Helper method to convert SwiftUI Color to UIColor (если еще нет)
    private func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
        if color == .red { return UIColor.systemRed }
        if color == .blue { return UIColor.systemBlue }
        if color == .green { return UIColor.systemGreen }
        if color == .yellow { return UIColor.systemYellow }
        if color == .orange { return UIColor.systemOrange }
        if color == .purple { return UIColor.systemPurple }
        if color == .pink { return UIColor.systemPink }
        if color == .gray { return UIColor.systemGray }
        if color == .brown { 
            if #available(iOS 15.0, *) {
                return UIColor.systemBrown
            } else {
                return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            }
        }
        if color == .mint { 
            if #available(iOS 15.0, *) {
                return UIColor.systemMint
            } else {
                return UIColor(red: 0, green: 0.8, blue: 0.6, alpha: 1.0)
            }
        }
        return UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup background image with the same logic as MainSceneView
        let backgroundImageView = UIImageView()
        let imageName = "location\(mainViewModel.currentScene?.id.description ?? "")"
        backgroundImageView.image = UIImage(named: imageName) ?? UIImage(named: "MainSceneBackground")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // Setup background constraints
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.backgroundColor = .black
        
        setupDustEffect()
        setupTopWidget()
        setupBottomWidget()
        setupButtonStacks()
        setupNPCsGrid()
        setupSelectedNPCInfo()
        setupNPCCountInfo()
        setupNPCWidgetOverlay()
        setupChat()
        setupLayout()
        setupNavigationObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDustEffectFrame()
    }
    
    // MARK: - Setup Methods
    
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
    
    private func updateDustEffectFrame() {
        dustEffectView?.view.frame = view.bounds
        if let dustView = dustEffectView?.view {
            view.insertSubview(dustView, aboveSubview: view.subviews.first!)
        }
    }
    
    private func setupButtonStacks() {
        // Left stack - now vertical container for action buttons with two rows
        leftButtonStackView.axis = .vertical
        leftButtonStackView.spacing = 8
        leftButtonStackView.alignment = .center
        leftButtonStackView.distribution = .equalSpacing
        leftButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftButtonStackView)
        
        // Chat buttons stack - vertical under chat
        chatButtonsStackView.axis = .vertical
        chatButtonsStackView.spacing = 6 // Reduced spacing
        chatButtonsStackView.alignment = .center
        chatButtonsStackView.distribution = .equalSpacing // Changed from fillEqually
        chatButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatButtonsStackView)
        
        updateButtonStacks()
    }
    
    private func setupNPCsGrid() {
        npcsGridContainerView.translatesAutoresizingMaskIntoConstraints = false
        npcsGridContainerView.backgroundColor = .clear
        view.addSubview(npcsGridContainerView)
        
        // Initial NPCs grid setup - will be updated by observer
        updateNPCsList(with: mainViewModel.npcs)
    }
    
    private func setupSelectedNPCInfo() {
        selectedNPCInfoView.translatesAutoresizingMaskIntoConstraints = false
        selectedNPCInfoView.isHidden = true
        view.addSubview(selectedNPCInfoView)
        // Initial update
        updateSelectedNPCInfo()
    }
    
    private func setupNPCCountInfo() {
        // NPC Count Info
        // private let npcCountInfoView = InfoPresentationLabelView()
        // Desired Victim Info
        // private let desiredVictimInfoView = InfoPresentationLabelView()
    }
    
    private func setupChat() {
        chatContainerView.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.backgroundColor = .clear
        view.addSubview(chatContainerView)
        
        // Create and add chat controller
        let chatVM = ChatViewModel()
        let chatController = ChatViewController(viewModel: chatVM)
        
        addChild(chatController)
        chatContainerView.addSubview(chatController.view)
        chatController.view.translatesAutoresizingMaskIntoConstraints = false
        chatController.didMove(toParent: self)
        
        self.chatViewController = chatController
        
        // Setup chat view constraints
        NSLayoutConstraint.activate([
            chatController.view.topAnchor.constraint(equalTo: chatContainerView.topAnchor),
            chatController.view.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
            chatController.view.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
            chatController.view.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor)
        ])

        // --- NEW: update chat header info ---
        updateChatHeaderInfo()
        // Подписка на изменения локации и NPC
        mainViewModel.$currentScene
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateChatHeaderInfo()
            }
            .store(in: &cancellables)
        mainViewModel.$npcs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateChatHeaderInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateChatHeaderInfo() {
        guard let chatVC = self.chatViewController else { return }
        let scene = mainViewModel.currentScene
        let locationName = scene?.name ?? "Unknown"
        let locationIcon = scene?.sceneType.iconName ?? "location"
        let locationColor = scene != nil ? SceneTypeColorProvider.color(for: scene!.sceneType) : UIColor.systemGray
        let npcCount = mainViewModel.npcs.count
        chatVC.updateHeaderInfo(locationName: locationName, locationIcon: locationIcon, locationColor: locationColor, npcCount: npcCount)
    }
    
    private func updateButtonStacks() {
        // Clear existing buttons
        leftButtonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chatButtonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Chat buttons (former left buttons) - now using ActionButtonRoundedSmallView
        if mainViewModel.isAdvanceTimeButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "hourglass.bottomhalf.fill", color: UIColor(Theme.textColor), size: 32) {
                self.mainViewModel.advanceTime()
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isBlacksmithButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "hammer.fill", color: UIColor(Theme.textColor), size: 32) {
                self.navigateTo(.smithing)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isQuestJournalButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "book.closed.fill", color: UIColor(Theme.textColor), size: 32) {
                self.navigateTo(.questJournal)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isNavigationButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "map.fill", color: UIColor(Theme.bloodProgressColor), size: 32) {
                self.navigateTo(.navigation)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isHidingCellButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "eye.circle.fill", color: UIColor(Theme.textColor), size: 32) {
                self.mainViewModel.getGameStateService().movePlayerToNearestHideout()
                self.navigateTo(.hidingCell)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isInvisibilityButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "eye.fill", color: UIColor(Theme.bloodProgressColor), size: 32) {
                // TODO: Show smoke effect and move to hideout
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isReappearButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "eye.slash", color: .red, size: 32) {
                self.mainViewModel.getGameStateService().movePlayerThroughHideouts(to: .none)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isWhisperButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: Ability.whisper.icon, color: .systemPink, size: 32) {
                self.mainViewModel.getGameStateService().whisperToRandomNpc()
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isInventoryButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "duffle.bag.fill", color: UIColor(Theme.bloodProgressColor), size: 32) {
                self.navigateTo(.inventory)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isAbilitiesButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "moon.stars.circle.fill", color: UIColor(Theme.bloodProgressColor), size: 32) {
                self.navigateTo(.abilities)
            }
            chatButtonsStackView.addArrangedSubview(button)
        }
        
        // Collect all action buttons first
        var actionButtons: [ActionButtonRoundedSmallView] = []
        
        if mainViewModel.isLootButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "bag.fill", color: UIColor(Theme.textColor), size: 32) {
                self.navigateTo(.loot)
            }
            actionButtons.append(button)
        }
        
        if mainViewModel.isConversationButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "bubble.left.fill", color: UIColor(Theme.textColor), size: 32) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.startConversation(selectedNPC))
                
                // Create DialogueViewModel and open dialogue
                if let dialogueVM = self.mainViewModel.createDialogueViewModel(for: selectedNPC) {
                    self.activeDialogueViewModel = dialogueVM
                    self.navigateTo(.dialogue)
                }
            }
            actionButtons.append(button)
        }
        
        if mainViewModel.isTradeButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "cart.fill", color: UIColor(Theme.textColor), size: 32) {
                self.navigateTo(.trade)
            }
            actionButtons.append(button)
        }
        
        if mainViewModel.isIntimidationButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "bolt.heart.fill", color: UIColor(Theme.bloodProgressColor), size: 32) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.startIntimidation(selectedNPC))
                // Handle VampireGaze - will be triggered by observer
            }
            actionButtons.append(button)
        }
        
        if mainViewModel.isFeedButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "drop.halffull", color: UIColor(Theme.bloodProgressColor), size: 32) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.feed(selectedNPC))
            }
            actionButtons.append(button)
        }
        
        if mainViewModel.isDrainButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "drop.fill", color: UIColor(Theme.bloodProgressColor), size: 32) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.drain(selectedNPC))
            }
            actionButtons.append(button)
        }
        
        if mainViewModel.isCombatButtonVisible() {
            let button = ActionButtonRoundedSmallView(icon: "flame", color: UIColor(Theme.bloodProgressColor), size: 32) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                GameStateService.shared.startCombat(npc: selectedNPC)
                // Combat will be triggered by notification observer
            }
            actionButtons.append(button)
        }
        
        // Create horizontal rows for action buttons
        if !actionButtons.isEmpty {
            // First row - up to 4 buttons
            let firstRowStack = UIStackView()
            firstRowStack.axis = .horizontal
            firstRowStack.spacing = 8
            firstRowStack.alignment = .center
            firstRowStack.distribution = .equalSpacing
            firstRowStack.translatesAutoresizingMaskIntoConstraints = false
            
            let firstRowButtons = Array(actionButtons.prefix(4))
            for button in firstRowButtons {
                firstRowStack.addArrangedSubview(button)
            }
            leftButtonStackView.addArrangedSubview(firstRowStack)
            
            // Second row - remaining buttons (if any)
            if actionButtons.count > 4 {
                let secondRowStack = UIStackView()
                secondRowStack.axis = .horizontal
                secondRowStack.spacing = 8
                secondRowStack.alignment = .center
                secondRowStack.distribution = .equalSpacing
                secondRowStack.translatesAutoresizingMaskIntoConstraints = false
                
                let secondRowButtons = Array(actionButtons.dropFirst(4))
                for button in secondRowButtons {
                    secondRowStack.addArrangedSubview(button)
                }
                leftButtonStackView.addArrangedSubview(secondRowStack)
            }
        }
    }
    
    private func setupTopWidget() {
        topWidgetContainerView.backgroundColor = .clear
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topWidgetContainerView)
        
        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC
    }
    
    private func setupBottomWidget() {
        bottomWidgetContainerView.backgroundColor = .clear
        bottomWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomWidgetContainerView)
        
        let widgetVC = BottomWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        bottomWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.bottomWidgetViewController = widgetVC
    }
    
    private func setupNPCWidgetOverlay() {
        npcWidgetOverlayView.translatesAutoresizingMaskIntoConstraints = false
        npcWidgetOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        npcWidgetOverlayView.isHidden = true
        npcWidgetOverlayView.alpha = 0
        view.addSubview(npcWidgetOverlayView)
        
        // Add tap gesture to close overlay when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissNPCWidget))
        npcWidgetOverlayView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            npcWidgetOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            npcWidgetOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            npcWidgetOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            npcWidgetOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func dismissNPCWidget(_ gesture: UITapGestureRecognizer) {
        print("dismissNPCWidget called")
        
        guard let widgetController = npcWidgetViewController else {
            print("No widget controller - hiding")
            hideNPCWidget()
            return
        }
        
        // Force layout update to ensure frame is correct
        npcWidgetOverlayView.layoutIfNeeded()
        
        // Get tap location in overlay view
        let tapLocation = gesture.location(in: npcWidgetOverlayView)
        
        // Convert widget bounds to overlay coordinate system
        let widgetBounds = widgetController.view.bounds
        let widgetFrameInOverlay = widgetController.view.convert(widgetBounds, to: npcWidgetOverlayView)
        
        // Debug information
        print("Tap location: \(tapLocation)")
        print("Widget frame in overlay: \(widgetFrameInOverlay)")
        
        // Check if tap is inside the widget view
        if widgetFrameInOverlay.contains(tapLocation) {
            print("Tap is INSIDE widget - not closing")
            return
        }
        
        print("Tap is OUTSIDE widget - closing")
        hideNPCWidget()
    }
    
    private func showNPCWidget(for npc: NPC) {
        // Remove existing widget if any
        if let existingController = npcWidgetViewController {
            existingController.willMove(toParent: nil)
            existingController.view.removeFromSuperview()
            existingController.removeFromParent()
        }
        
        // Create new NPCWidget
        let npcWidget = NPCWidget(
            npc: npc,
            isSelected: true,
            isDisabled: false,
            showCurrentActivity: true,
            showResistance: false,
            onTap: { 
                // Do nothing - don't close on widget tap
            },
            onAction: { [weak self] action in
                self?.mainViewModel.handleNPCAction(action)
                self?.hideNPCWidget()
            }
        )
        
        let hostingController = UIHostingController(rootView: npcWidget)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(hostingController)
        npcWidgetOverlayView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        self.npcWidgetViewController = hostingController
        
        // Center the widget
        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: npcWidgetOverlayView.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: npcWidgetOverlayView.centerYAnchor),
            hostingController.view.widthAnchor.constraint(equalToConstant: 180),
            hostingController.view.heightAnchor.constraint(equalToConstant: 320)
        ])
        
        // Set initial state for smooth animation
        npcWidgetOverlayView.alpha = 0
        hostingController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Show with smooth animation
        npcWidgetOverlayView.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseOut], animations: {
            self.npcWidgetOverlayView.alpha = 1
            hostingController.view.transform = .identity
        }, completion: nil)
        
        isNPCWidgetVisible = true
    }
    
    private func hideNPCWidget() {
        guard isNPCWidgetVisible else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.npcWidgetOverlayView.alpha = 0
        }) { _ in
            self.npcWidgetOverlayView.isHidden = true
            
            // Remove widget controller
            if let controller = self.npcWidgetViewController {
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self.npcWidgetViewController = nil
            }
        }
        
        isNPCWidgetVisible = false
    }
    
    private func setupLayout() {
        // Chat container - positioned at the top right after top widget (first position)
        let chatTop = chatContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 10)
        let chatTrailing = chatContainerView.trailingAnchor.constraint(equalTo: chatButtonsStackView.leadingAnchor, constant: -10)
        let chatWidth = chatContainerView.widthAnchor.constraint(equalToConstant: 200)
        chatContainerHeightConstraint = chatContainerView.heightAnchor.constraint(equalToConstant: NPCInteractionManager.shared.selectedNPC != nil ? 140 : 300)

        NSLayoutConstraint.activate([
            // Top widget - exactly like CharacterInventoryViewController
            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),
            // Top widget content
            topWidgetViewController!.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor),
            topWidgetViewController!.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor),
            topWidgetViewController!.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor),
            topWidgetViewController!.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor),
            // Bottom widget - centered at the very bottom of the screen (outside safe area)
            bottomWidgetContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            bottomWidgetContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomWidgetContainerView.widthAnchor.constraint(equalToConstant: 700),
            bottomWidgetContainerView.heightAnchor.constraint(equalToConstant: 80),
            // Bottom widget content
            bottomWidgetViewController!.view.topAnchor.constraint(equalTo: bottomWidgetContainerView.topAnchor),
            bottomWidgetViewController!.view.leadingAnchor.constraint(equalTo: bottomWidgetContainerView.leadingAnchor),
            bottomWidgetViewController!.view.trailingAnchor.constraint(equalTo: bottomWidgetContainerView.trailingAnchor),
            bottomWidgetViewController!.view.bottomAnchor.constraint(equalTo: bottomWidgetContainerView.bottomAnchor),
            // Chat container
            chatTop,
            chatTrailing,
            chatWidth,
            chatContainerHeightConstraint!,
            // Selected NPC Info - positioned below chat (second position)
            selectedNPCInfoView.topAnchor.constraint(equalTo: chatContainerView.bottomAnchor, constant: 10),
            selectedNPCInfoView.trailingAnchor.constraint(equalTo: chatButtonsStackView.leadingAnchor, constant: -10),
            selectedNPCInfoView.widthAnchor.constraint(equalToConstant: 200), // Same width as chat
            selectedNPCInfoView.heightAnchor.constraint(equalToConstant: 100), // Height for avatar + padding
            // Action buttons stack - positioned below selected NPC info (third position in right column)
            leftButtonStackView.topAnchor.constraint(equalTo: selectedNPCInfoView.bottomAnchor, constant: 10),
            leftButtonStackView.trailingAnchor.constraint(equalTo: chatButtonsStackView.leadingAnchor, constant: -10),
            leftButtonStackView.widthAnchor.constraint(equalToConstant: 200), // Same width as chat
            // NPCs Grid - positioned below top widget, between left edge and chat area, with bottom constraint adjusted
            npcsGridContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 10),
            npcsGridContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            npcsGridContainerView.trailingAnchor.constraint(equalTo: chatContainerView.leadingAnchor, constant: -10),
            npcsGridContainerView.heightAnchor.constraint(equalToConstant: 300),
            // Chat buttons stack - positioned on the right edge, spanning from top to bottom widget
            chatButtonsStackView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 10),
            chatButtonsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            chatButtonsStackView.widthAnchor.constraint(equalToConstant: 40),
            chatButtonsStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomWidgetContainerView.topAnchor, constant: -10),
        ])
    }
    
    private func updateChatContainerHeight() {
        let newHeight: CGFloat = NPCInteractionManager.shared.selectedNPC != nil ? 100 : 300
        if chatContainerHeightConstraint?.constant != newHeight {
            chatContainerHeightConstraint?.constant = newHeight
            // Убрана анимация и layoutIfNeeded
        }
    }
    
    // MARK: - Navigation Setup
    
    private func setupNavigationObservers() {
        // Subscribe to dialogue trigger notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenDialogueTrigger(_:)),
            name: Notification.Name("openDialogueTrigger"),
            object: nil
        )
        
        // Subscribe to return to main scene notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReturnToMainScene),
            name: Notification.Name("returnToMainScene"),
            object: nil
        )
        
        // Subscribe to start battle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartBattle(_:)),
            name: Notification.Name("startBattle"),
            object: nil
        )
        
        // Subscribe to vampire gaze view changes
        mainViewModel.$isShowingVampireGazeView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isShowing in
                if isShowing {
                    self?.navigateTo(.vampireGaze)
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func handleOpenDialogueTrigger(_ notification: Notification) {
        // Defensive programming: ensure we're on main thread and have valid userInfo
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleOpenDialogueTrigger(notification)
            }
            return
        }
        
        guard let userInfo = notification.userInfo,
              !userInfo.isEmpty else {
            print("Error: Received .openDialogueTrigger notification with nil or empty userInfo.")
            return
        }
        
        // Safely extract the dialogue filename with type checking
        guard let dialogueFilename = userInfo["specificDialogueFilename"] as? String,
              !dialogueFilename.isEmpty else {
            print("Error: .openDialogueTrigger missing or invalid 'specificDialogueFilename' in userInfo: \(userInfo)")
            return
        }
        
        // Safely extract other values with proper type checking
        let forceOpen = (userInfo["forceOpen"] as? NSNumber)?.boolValue ?? false
        let targetNPCId = (userInfo["targetNPCId"] as? NSNumber)?.intValue
        let interactingNPCIdFromQuest = (userInfo["interactingNPCId"] as? NSNumber)?.intValue
        
        print("Received .openDialogueTrigger: file='\(dialogueFilename)', targetNPCId=\(targetNPCId ?? -1), forceOpen=\(forceOpen)")
        
        var npcForDialogue: NPC? = nil
        let npcManager = NPCInteractionManager.shared
        
        if forceOpen {
            if let npcId = targetNPCId {
                npcForDialogue = NPCReader.getRuntimeNPC(by: npcId)
                if npcForDialogue == nil {
                    print("Warning: forceOpen dialogue trigger for targetNPCId \(npcId) but NPC not found.")
                }
            }
        } else {
            let currentInteractingNPC = npcManager.selectedNPC
            
            if let tid = targetNPCId {
                if currentInteractingNPC?.id == tid {
                    npcForDialogue = currentInteractingNPC
                } else {
                    print("Info: .openDialogueTrigger for targetNPCId \(tid) but current NPC is \(currentInteractingNPC?.id ?? -1). Dialogue not opened.")
                    return
                }
            } else if let qNPCId = interactingNPCIdFromQuest {
                if currentInteractingNPC?.id == qNPCId {
                    npcForDialogue = currentInteractingNPC
                } else {
                    print("Info: .openDialogueTrigger with interactingNPCIdFromQuest \(qNPCId) but current NPC is \(currentInteractingNPC?.id ?? -1). Dialogue not opened.")
                    return
                }
            } else if currentInteractingNPC != nil {
                npcForDialogue = currentInteractingNPC
            } else {
                print("Warning: .openDialogueTrigger (not forced) but no NPC context available. Dialogue not opened.")
                return
            }
        }
        
        guard let player = mainViewModel.gameStateService.player else {
            print("Error: .openDialogueTrigger - player object is nil.")
            return
        }
        
        let dialogueVM = DialogueViewModel(npc: npcForDialogue!, player: player, specificDialogueFilename: dialogueFilename)
        activeDialogueViewModel = dialogueVM
        
        DispatchQueue.main.async {
            self.popToRoot()
            self.navigateTo(.dialogue)
        }
    }
    
    @objc private func handleReturnToMainScene() {
        DispatchQueue.main.async {
            self.popToRoot()
        }
    }
    
    @objc private func handleStartBattle(_ notification: Notification) {
        guard notification.object is NPC else {
            print("Error: startBattle notification - NPC object is missing.")
            return
        }
        
        DispatchQueue.main.async {
            self.navigateTo(.combat)
        }
    }
    
    // MARK: - Navigation Methods
    
    func navigateTo(_ destination: NavigationDestination) {
        let destinationVC: UIViewController
        
        switch destination {
        case .navigation:
            let worldMapView = WorldMapViewRepresentable(mainViewModel: mainViewModel)
            let hostingController = UIHostingController(rootView: worldMapView)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .dialogue:
            guard let dialogueViewModel = activeDialogueViewModel else {
                print("Error: No active dialogue view model")
                return
            }
            
            let dialogueWrapper = DialogueViewControllerWrapper(
                viewModel: dialogueViewModel,
                mainViewModel: mainViewModel,
                isSkipable: !dialogueViewModel.isSpecificDialogueSet,
                onDismiss: { [weak self] in
                    self?.activeDialogueViewModel = nil
                    self?.popCurrent()
                }
            )
            let hostingController = UIHostingController(rootView: dialogueWrapper)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .vampireGaze:
            guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else {
                print("Error: No selected NPC for vampire gaze")
                return
            }
            
            let vampireGazeView = VampireGazeView(
                npc: selectedNPC,
                isPresented: .constant(true),
                mainViewModel: mainViewModel
            )
            let hostingController = UIHostingController(rootView: vampireGazeView)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .trade:
            guard let selectedNPC = NPCInteractionManager.shared.selectedNPC,
                  let player = mainViewModel.gameStateService.player,
                  let scene = mainViewModel.gameStateService.currentScene else {
                print("Error: Missing requirements for trade")
                return
            }
            
            let tradeWrapper = TradeViewControllerWrapper(
                player: player,
                npc: selectedNPC,
                scene: scene,
                mainViewModel: mainViewModel
            )
            let hostingController = UIHostingController(rootView: tradeWrapper)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .inventory:
            guard let player = mainViewModel.gameStateService.player,
                  let scene = mainViewModel.gameStateService.currentScene else {
                print("Error: Missing requirements for inventory")
                return
            }
            
            let inventoryWrapper = CharacterInventoryViewControllerWrapper(
                character: player,
                scene: scene,
                mainViewModel: mainViewModel,
                onDismiss: { [weak self] in
                    self?.popCurrent()
                }
            )
            let hostingController = UIHostingController(rootView: inventoryWrapper)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .smithing:
            guard let player = mainViewModel.gameStateService.player else {
                print("Error: Missing player for smithing")
                return
            }
            
            let smithingWrapper = SmithingViewControllerWrapper(
                player: player,
                mainViewModel: mainViewModel,
                onDismiss: { [weak self] in
                    self?.popCurrent()
                }
            )
            let hostingController = UIHostingController(rootView: smithingWrapper)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .abilities:
            guard let scene = mainViewModel.gameStateService.currentScene else {
                print("Error: Missing scene for abilities")
                return
            }
            
            let abilitiesWrapper = AbilitiesViewControllerWrapper(
                scene: scene,
                mainViewModel: mainViewModel,
                onDismiss: { [weak self] in
                    self?.popCurrent()
                }
            )
            let hostingController = UIHostingController(rootView: abilitiesWrapper)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .loot:
            guard let selectedNPC = NPCInteractionManager.shared.selectedNPC,
                  let player = mainViewModel.gameStateService.player,
                  let scene = mainViewModel.gameStateService.currentScene else {
                print("Error: Missing requirements for loot")
                return
            }
            
            let lootView = LootView(
                player: player,
                npc: selectedNPC,
                scene: scene,
                mainViewModel: mainViewModel
            )
            let hostingController = UIHostingController(rootView: lootView)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .questJournal:
            let questJournalView = QuestJournalView(mainSceneViewModel: mainViewModel)
            let hostingController = UIHostingController(rootView: questJournalView)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .hidingCell:
            let hidingCellView = HidingCellView(mainSceneViewModel: mainViewModel)
            let hostingController = UIHostingController(rootView: hidingCellView)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
            
        case .combat:
            guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else {
                print("Error: No selected NPC for combat")
                return
            }
            
            let combatView = CombatViewRepresentable(
                mainViewModel: mainViewModel,
                npc: selectedNPC,
                onLeave: { [weak self] in
                    self?.popCurrent()
                },
                onLoot: { [weak self] in
                    self?.navigateTo(.loot)
                }
            )
            let hostingController = UIHostingController(rootView: combatView)
            hostingController.view.backgroundColor = .black
            destinationVC = hostingController
        }
        
        // Hide navigation bar for all destinations
        destinationVC.navigationItem.hidesBackButton = true
        destinationVC.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Add swipe to dismiss gesture only for allowed destinations
        if shouldAddSwipeGesture(for: destination) {
            addSwipeToDismissGesture(to: destinationVC)
        }
        
        // Push the view controller
        if let navigationController = self.customNavigationController {
            navigationController.pushViewController(destinationVC, animated: true)
        } else {
            // Create navigation controller if it doesn't exist
            let navController = UINavigationController(rootViewController: self)
            navController.setNavigationBarHidden(true, animated: false)
            self.customNavigationController = navController
            navController.pushViewController(destinationVC, animated: true)
        }
    }
    
    private func addSwipeToDismissGesture(to viewController: UIViewController) {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToDismiss))
        swipeGesture.direction = .right
        viewController.view.addGestureRecognizer(swipeGesture)
    }
    
    // Новый метод для проверки, нужно ли добавлять жест свайпа
    private func shouldAddSwipeGesture(for destination: NavigationDestination) -> Bool {
        switch destination {
        case .combat, .navigation, .hidingCell:
            return false // Запрещаем свайп для боя, карты и убежища
        default:
            return true // Разрешаем свайп для остальных экранов
        }
    }
    
    @objc private func handleSwipeToDismiss() {
        popCurrent()
    }
    
    func popCurrent() {
        customNavigationController?.popViewController(animated: true)
    }
    
    func popToRoot() {
        customNavigationController?.popToRootViewController(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI Wrapper
struct SceneView: UIViewControllerRepresentable {
    let mainViewModel: MainSceneViewModel
    
    func makeUIViewController(context: Context) -> SceneViewController {
        return SceneViewController(mainViewModel: mainViewModel)
    }
    
    func updateUIViewController(_ uiViewController: SceneViewController, context: Context) {
        // Updates can be handled here if needed
    }
} 
