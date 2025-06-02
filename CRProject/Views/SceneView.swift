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
        let currentTime = Date()
        if let lastTapTime = lastTapTimes[npc.id], currentTime.timeIntervalSince(lastTapTime) < 0.3 {
            // Double tap detected - show NPC widget and trigger investigate action
            print("Double tap detected on NPC: \(npc.name)")
            onDoubleTap(npc)
            // Also call the original onAction for investigate (like the parent class does)
            if let onAction = getOnAction() {
                print("Calling onAction(.investigate) for NPC: \(npc.name)")
                onAction(.investigate(npc))
            }
            lastTapTimes[npc.id] = nil
        } else {
            // Single tap - update selection (same as parent class behavior)
            print("Single tap on NPC: \(npc.name)")
            let oldSelectedNPC = npcManager.selectedNPC
            npcManager.select(with: npc)
            
            // Update cells for both the previously selected NPC and newly selected NPC
            if let oldNPC = oldSelectedNPC {
                updateNPCCell(for: oldNPC)
            }
            updateNPCCell(for: npc)
            
            lastTapTimes[npc.id] = currentTime
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
    
    // Dust effect
    private var dustEffectView: UIHostingController<DustEmitterView>?
    
    // Button stacks
    private let leftButtonStackView = UIStackView()
    private let rightButtonStackView = UIStackView()
    
    // NPCs Grid View
    private let npcsGridContainerView = UIView()
    private var npcsGridView: NPCSGridView?
    
    // NPC Widget Overlay
    private let npcWidgetOverlayView = UIView()
    private var npcWidgetViewController: UIHostingController<NPCWidget>?
    private var isNPCWidgetVisible = false
    
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
    }
    
    private func updateNPCsList(with newNPCs: [NPC]) {
        // Remove existing grid view
        npcsGridView?.removeFromSuperview()
        
        // Create new NPCSGridView with updated NPCs
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
        npcsGridContainerView.addSubview(gridView)
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
        setupButtonStacks()
        setupNPCsGrid()
        setupNPCWidgetOverlay()
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
        // Left stack
        leftButtonStackView.axis = .vertical
        leftButtonStackView.spacing = 4
        leftButtonStackView.alignment = .center
        leftButtonStackView.distribution = .fill
        leftButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftButtonStackView)
        
        // Right stack
        rightButtonStackView.axis = .vertical
        rightButtonStackView.spacing = 4
        rightButtonStackView.alignment = .center
        rightButtonStackView.distribution = .fill
        rightButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightButtonStackView)
        
        updateButtonStacks()
    }
    
    private func setupNPCsGrid() {
        npcsGridContainerView.translatesAutoresizingMaskIntoConstraints = false
        npcsGridContainerView.backgroundColor = .clear
        view.addSubview(npcsGridContainerView)
        
        // Initial NPCs grid setup - will be updated by observer
        updateNPCsList(with: mainViewModel.npcs)
    }
    
    private func updateButtonStacks() {
        // Clear existing buttons
        leftButtonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rightButtonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Left buttons
        if mainViewModel.isAdvanceTimeButtonVisible() {
            let button = ActionButtonSmallView(title: "Time", icon: "hourglass.bottomhalf.fill", color: UIColor(Theme.textColor)) {
                self.mainViewModel.advanceTime()
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isBlacksmithButtonVisible() {
            let button = ActionButtonSmallView(title: "Smith", icon: "hammer.fill", color: UIColor(Theme.textColor)) {
                self.navigateTo(.smithing)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isQuestJournalButtonVisible() {
            let button = ActionButtonSmallView(title: "Journal", icon: "book.closed.fill", color: UIColor(Theme.textColor)) {
                self.navigateTo(.questJournal)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isNavigationButtonVisible() {
            let button = ActionButtonSmallView(title: "Map", icon: "map.fill", color: UIColor(Theme.bloodProgressColor)) {
                self.navigateTo(.navigation)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isHidingCellButtonVisible() {
            let button = ActionButtonSmallView(title: "Hide", icon: "eye.circle.fill", color: UIColor(Theme.textColor)) {
                self.mainViewModel.getGameStateService().movePlayerToNearestHideout()
                self.navigateTo(.hidingCell)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isInvisibilityButtonVisible() {
            // TODO: Handle multiple hideouts
            let button = ActionButtonSmallView(title: "Invis", icon: "eye.fill", color: UIColor(Theme.bloodProgressColor)) {
                // TODO: Show smoke effect and move to hideout
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isReappearButtonVisible() {
            let button = ActionButtonSmallView(title: "Appear", icon: "eye.slash", color: .red) {
                self.mainViewModel.getGameStateService().movePlayerThroughHideouts(to: .none)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isWhisperButtonVisible() {
            let button = ActionButtonSmallView(title: "Whisper", icon: Ability.whisper.icon, color: .systemPink) {
                self.mainViewModel.getGameStateService().whisperToRandomNpc()
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isInventoryButtonVisible() {
            let button = ActionButtonSmallView(title: "Bag", icon: "duffle.bag.fill", color: UIColor(Theme.bloodProgressColor)) {
                self.navigateTo(.inventory)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isAbilitiesButtonVisible() {
            let button = ActionButtonSmallView(title: "Skills", icon: "moon.stars.circle.fill", color: UIColor(Theme.bloodProgressColor)) {
                self.navigateTo(.abilities)
            }
            leftButtonStackView.addArrangedSubview(button)
        }
        
        // Right buttons
        if mainViewModel.isLootButtonVisible() {
            let button = ActionButtonSmallView(title: "Loot", icon: "bag.fill", color: UIColor(Theme.textColor)) {
                self.navigateTo(.loot)
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isConversationButtonVisible() {
            let button = ActionButtonSmallView(title: "Talk", icon: "bubble.left.fill", color: UIColor(Theme.textColor)) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.startConversation(selectedNPC))
                
                // Create DialogueViewModel and open dialogue
                if let dialogueVM = self.mainViewModel.createDialogueViewModel(for: selectedNPC) {
                    self.activeDialogueViewModel = dialogueVM
                    self.navigateTo(.dialogue)
                }
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isTradeButtonVisible() {
            let button = ActionButtonSmallView(title: "Trade", icon: "cart.fill", color: UIColor(Theme.textColor)) {
                self.navigateTo(.trade)
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isIntimidationButtonVisible() {
            let button = ActionButtonSmallView(title: "Gaze", icon: "bolt.heart.fill", color: UIColor(Theme.bloodProgressColor)) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.startIntimidation(selectedNPC))
                // Handle VampireGaze - will be triggered by observer
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isFeedButtonVisible() {
            let button = ActionButtonSmallView(title: "Feed", icon: "drop.halffull", color: UIColor(Theme.bloodProgressColor)) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.feed(selectedNPC))
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isDrainButtonVisible() {
            let button = ActionButtonSmallView(title: "Drain", icon: "drop.fill", color: UIColor(Theme.bloodProgressColor)) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                self.mainViewModel.handleNPCAction(.drain(selectedNPC))
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        if mainViewModel.isCombatButtonVisible() {
            let button = ActionButtonSmallView(title: "Fight", icon: "flame", color: UIColor(Theme.bloodProgressColor)) {
                guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return }
                GameStateService.shared.startCombat(npc: selectedNPC)
                // Combat will be triggered by notification observer
            }
            rightButtonStackView.addArrangedSubview(button)
        }
        
        // Add spacers at the end
        let leftSpacer = UIView()
        leftSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        leftButtonStackView.addArrangedSubview(leftSpacer)
        
        let rightSpacer = UIView()
        rightSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        rightButtonStackView.addArrangedSubview(rightSpacer)
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
            
            // Left button stack - increased width to accommodate ActionButtonSmallView
            leftButtonStackView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            leftButtonStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            leftButtonStackView.widthAnchor.constraint(equalToConstant: 120),
            leftButtonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Right button stack - increased width to accommodate ActionButtonSmallView
            rightButtonStackView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            rightButtonStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            rightButtonStackView.widthAnchor.constraint(equalToConstant: 120),
            rightButtonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // NPCs Grid - center area between button stacks
            npcsGridContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            npcsGridContainerView.leadingAnchor.constraint(equalTo: leftButtonStackView.trailingAnchor, constant: 10),
            npcsGridContainerView.trailingAnchor.constraint(equalTo: rightButtonStackView.leadingAnchor, constant: -10),
            npcsGridContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
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
        guard let userInfo = notification.userInfo else {
            print("Error: Received .openDialogueTrigger notification with nil userInfo.")
            return
        }
        
        guard let dialogueFilename = userInfo["specificDialogueFilename"] as? String else {
            print("Error: .openDialogueTrigger missing 'specificDialogueFilename' in userInfo")
            return
        }
        
        let forceOpen = userInfo["forceOpen"] as? Bool ?? false
        let targetNPCId = userInfo["targetNPCId"] as? Int
        let interactingNPCIdFromQuest = userInfo["interactingNPCId"] as? Int
        
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
        guard let npc = notification.object as? NPC else {
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
        
        // Add swipe to dismiss gesture
        addSwipeToDismissGesture(to: destinationVC)
        
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
