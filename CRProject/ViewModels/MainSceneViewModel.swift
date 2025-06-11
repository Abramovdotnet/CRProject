import Foundation
import Combine
import SwiftUI

class MainSceneViewModel: ObservableObject {
    @Published var currentScene: Scene?
    @Published var parentScene: Scene?
    @Published var childScenes: [Scene] = []
    @Published var siblingScenes: [Scene] = []
    @Published var npcs: [NPC] = []
    @Published var sceneAwareness: Float = 0
    @Published var playerBloodPercentage: Float = 100
    @Published var currentDay: Int = 1
    @Published var currentHour: Int = 0
    @Published var currentMinute: Int = 0
    @Published var isNight: Bool = false
    @Published var isGameEnd: Bool = false
    @Published var sceneSplit: Int = 0
    @Published var selectedItemIndex: Int = 0
    @Published private(set) var locationPositions: [Int: CGPoint]?
    @Published private(set) var visibleLocations: Set<Int> = []
    @Published var playerCoinsValue: Int = 0
    @Published var isShowingVampireGazeView = false
    
    // UI state tracking
    @Published var shouldUpdateButtons = false
    @Published var shouldUpdateNPCsList = false
    
    private var cancellables = Set<AnyCancellable>()
    let gameStateService: GameStateService
    private let vampireNatureRevealService: VampireNatureRevealService
    private let feedingService: FeedingService
    private let investigationService: InvestigationService
    private let bloodManagementService: BloodManagementService
    private let gameTime: GameTimeService
    
    @ObservedObject private var npcManager = NPCInteractionManager.shared
    
    init(gameStateService: GameStateService = DependencyManager.shared.resolve(),
         vampireNatureRevealService: VampireNatureRevealService = DependencyManager.shared.resolve(),
         feedingService: FeedingService = DependencyManager.shared.resolve(),
         investigationService: InvestigationService = DependencyManager.shared.resolve(),
         bloodManagementService: BloodManagementService = DependencyManager.shared.resolve(),
         gameTime: GameTimeService = DependencyManager.shared.resolve()) {
        self.gameStateService = gameStateService
        self.vampireNatureRevealService = vampireNatureRevealService
        self.feedingService = feedingService
        self.investigationService = investigationService
        self.bloodManagementService = bloodManagementService
        self.gameTime = gameTime
        
        // Create and set player
        let initialPlayer = NPCGenerator.createPlayer()
        initialPlayer.coins.add(100)
        gameStateService.setPlayer(initialPlayer)
     
        ItemsManagementService.shared.giveItem(itemId: 181, to: initialPlayer)
        
        for _ in 0..<3 {
            ItemsManagementService.shared.giveItem(itemId: 1001, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1002, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1003, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1004, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1005, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1006, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1007, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1008, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1009, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1010, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1011, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1012, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1013, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1014, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1015, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1016, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1017, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1018, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1019, to: initialPlayer)
            ItemsManagementService.shared.giveItem(itemId: 1020, to: initialPlayer)
              ItemsManagementService.shared.giveItem(itemId: 165, to: initialPlayer)
                ItemsManagementService.shared.giveItem(itemId: 258, to: initialPlayer)
        }
        
        // Initialize playerCoinsValue
        self.playerCoinsValue = initialPlayer.coins.value
        
        // Subscribe to player's coins value changes
        initialPlayer.coins.$value
            .sink { [weak self] newValue in
                // Update the ViewModel's published property on the main thread
                DispatchQueue.main.async {
                    self?.playerCoinsValue = newValue
                }
            }
            .store(in: &cancellables)
        
        resetDesires()
        
        // Subscribe to scene changes
        gameStateService.$currentScene
            .sink { [weak self] scene in
                self?.currentScene = scene
                self?.updateRelatedLocations(for: scene?.id ?? 0)
                // Update NPCs when scene changes
                if let npcs = scene?.getNPCs() {
                    DebugLogService.shared.log("Found \(npcs.count) NPCs in scene \(scene?.name ?? "unknown")", category: "Scene")
                    self?.npcs = npcs
                } else {
                    DebugLogService.shared.log("No NPCs found in scene", category: "Scene")
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to scene character changes
        NotificationCenter.default.publisher(for: Notification.Name("sceneCharactersChanged"))
            .sink { [weak self] notification in
                guard let scene = notification.object as? Scene,
                      scene.id == self?.currentScene?.id else { return }
                let characters = scene.getCharacters()
                self?.npcs = characters.compactMap { $0 as? NPC }
            }
            .store(in: &cancellables)
        
        // Subscribe to parent scene changes
        gameStateService.$parentScene
            .assign(to: &$parentScene)
        
        // Subscribe to child scenes changes
        gameStateService.$childScenes
            .assign(to: &$childScenes)
        
        // Subscribe to sibling scenes changes
        gameStateService.$siblingScenes
            .assign(to: &$siblingScenes)
        
        // Subscribe to awareness changes
        vampireNatureRevealService.exposedPublisher
            .sink { [weak self] sceneId in
                guard let self = self,
                      sceneId == self.currentScene?.id else { return }
                self.sceneAwareness = 100
            }
            .store(in: &cancellables)
         
        // Subscribe to awareness changes
        NotificationCenter.default
            .publisher(for: .awarenessIncreased)
            .sink { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.updateSceneAwareness()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to time advancement notifications
        NotificationCenter.default
            .publisher(for: .timeAdvanced)
            .sink { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.updateSceneAwareness()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to day changes
        gameTime.$currentDay
            .sink { [weak self] day in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.currentDay = day
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to hour changes
        gameTime.$currentHour
            .sink { [weak self] hour in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.currentHour = hour
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to minute changes
        gameTime.$currentMinute
            .sink { [weak self] minute in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.currentMinute = minute
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to night/day changes
        gameTime.$isNightTime
            .sink { [weak self] isNight in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.isNight = isNight
                }
                // Trigger UI updates
                self?.shouldUpdateButtons.toggle()
            }
            .store(in: &cancellables)
        
        // Subscribe to NPC manager changes
        npcManager.$selectedNPC
            .sink { [weak self] _ in
                self?.shouldUpdateButtons.toggle()
            }
            .store(in: &cancellables)
        
        // Subscribe to player state changes
        initialPlayer.$isArrested
            .sink { [weak self] _ in
                self?.shouldUpdateButtons.toggle()
            }
            .store(in: &cancellables)
        
        // Monitor player hiding state changes using a timer (since hiddenAt is not @Published)
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkPlayerStateChanges()
            }
            .store(in: &cancellables)
        
        // Create initial scene using LocationReader
        do {
            let initialScene = try LocationReader.getRuntimeLocation(by: 2)
            try gameStateService.changeLocation(to: initialScene.id)
            
            // Set default awareness to 0
            vampireNatureRevealService.decreaseAwareness(amount: 100)
        } catch {
            DebugLogService.shared.log("Error creating initial scene: \(error)", category: "Error")
        }
  
        NotificationCenter.default.publisher(for: .exposed)
            .sink { [weak self] _ in
                self?.endGame()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Player State Monitoring
    
    private var lastPlayerHiddenState: HidingCell = .none
    
    private func checkPlayerStateChanges() {
        guard let player = gameStateService.player else { return }
        
        // Check if hiding state changed
        if player.hiddenAt != lastPlayerHiddenState {
            lastPlayerHiddenState = player.hiddenAt
            shouldUpdateButtons.toggle()
        }
    }
    
    func navigateToParent() {
        guard let parentScene = parentScene else { return }
        
        // Store current positions for animation
        let oldPositions = locationPositions
        
        try? gameStateService.changeLocation(to: parentScene.id)
        currentScene = gameStateService.currentScene
        
        // Trigger position update with animation
        withAnimation(.easeInOut(duration: 0.6)) {
            if let oldPos = oldPositions {
                locationPositions = oldPos
            }
            updateSceneAwareness()

        }
    }
    
    func navigateToChild(_ scene: Scene) {
        // Store current positions for animation
        let oldPositions = locationPositions
        
        try? gameStateService.changeLocation(to: scene.id)
        currentScene = gameStateService.currentScene
    }
    
    func navigateToSibling(_ scene: Scene) {
        // Store current positions for animation
        let oldPositions = locationPositions
        
        try? gameStateService.changeLocation(to: scene.id)
        currentScene = gameStateService.currentScene
    }
    
    // MARK: - NPC Management
    func endGame(){
        isGameEnd = true
    }
    
    func investigateNPC(_ npc: NPC) {
        guard let player = gameStateService.getPlayer(),
              investigationService.canInvestigate(inspector: player, investigationObject: npc) else {
            return
        }
        investigationService.investigate(inspector: player, investigationObject: npc)    }
    
    func resetAwareness() {
        vampireNatureRevealService.decreaseAwareness(amount: 100)
    }
    
    func resetBloodPool() {
        guard let player = GameStateService.shared.player else { return }
        
        player.bloodMeter.addBlood(100)
    }
    
    func resetDesires() {
        guard let player = GameStateService.shared.player else { return }
        player.desiredVictim.updateDesiredVictim()
    }
    
    // MARK: - Blood Management
    func feedOnCharacter(_ npc: NPC) {
        guard let player = gameStateService.getPlayer(),
              feedingService.canFeed(vampire: player, prey: npc) else {
            return
        }
        let sceneId = currentScene?.id ?? 0
        do {
            try feedingService.feedOnCharacter(vampire: player, prey: npc, amount: 30, in: sceneId)

            DebugLogService.shared.log("\(sceneAwareness)", category: "Debug")
        } catch {
            DebugLogService.shared.log("Error feeding on character: \(error)", category: "Error")
        }
    }
    
    func emptyBloodFromCharacter(_ npc: NPC) {
        guard let player = gameStateService.getPlayer(),
              feedingService.canFeed(vampire: player, prey: npc) else {
            return
        }
        do {
            try feedingService.emptyBlood(vampire: player, prey: npc, in: currentScene?.id ?? 0)
            DebugLogService.shared.log("Blood emptied", category: "Debug")
        } catch {
        }
    }
    
    func canFeedOnCharacter(_ npc: NPC) -> Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        return feedingService.canFeed(vampire: player, prey: npc)
    }
    
    func canInvestigateNPC(_ npc: NPC) -> Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        return investigationService.canInvestigate(inspector: player, investigationObject: npc)
    }
    
    // MARK: - Private Methods
    private func updateRelatedLocations(for locationId: Int) {
        DebugLogService.shared.log("DEBUG: Starting updateRelatedLocations for ID: \(locationId)", category: "Debug")
        
        // Get parent location
        parentScene = LocationReader.getParentLocation(for: locationId)
        DebugLogService.shared.log("DEBUG: Parent scene loaded: \(parentScene?.name ?? "None") with ID: \(parentScene?.id.description ?? "No ID")", category: "Debug")
        
        // Get child locations
        childScenes = LocationReader.getChildLocations(for: locationId)
        DebugLogService.shared.log("DEBUG: Child scenes count: \(childScenes.count)", category: "Debug")
        
        // Removed direct assignment to siblingScenes here to avoid redundancy and ensure single source of truth.
        // siblingScenes = LocationReader.getSiblingLocations(for: locationId)
        // DebugLogService.shared.log("DEBUG: Sibling scenes count: \(siblingScenes.count)", category: "Debug")
    }
    
    func updateSceneAwareness() {
        withAnimation(.easeInOut(duration: 0.3)) {
            guard (currentScene?.id) != nil else { return }
            sceneAwareness = vampireNatureRevealService.getAwareness()
        }
    }
    
    func getLocationAwareness(_ scene: Scene) -> Float {
        return vampireNatureRevealService.getAwareness()
    }
    
    func canSkipTimeSafe() -> Bool {
        _ = [.tavern, .brothel, .cemetery, .house ,.warehouse]
            .contains(currentScene?.sceneType)
            && !isNight
        && isAwarenessSafe
        
        return !isNight
    }
    
    var isAwarenessSafe: Bool {
        guard let currentSceneId = currentScene?.id else { return true }
        return vampireNatureRevealService.getAwareness() < 100
    }
    
    func skipTimeToNight() {
        withAnimation(.easeInOut(duration: 0.3)) {
            while !gameTime.isNightTime {
                gameTime.advanceTimeSafe()
            }
        }
    }
    
    func advanceTime() {
        withAnimation(.easeInOut(duration: 0.3)) {
            gameTime.advanceTime()
        }
    }
    
    func updateLocationPositions(in geometry: GeometryProxy) {
        // Debounce rapid updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Calculate new positions
            let newPositions = self.calculateLocationPositions(in: geometry)
            
            // Only update if positions have changed significantly
            if self.shouldUpdatePositions(newPositions) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.locationPositions = newPositions
                    self.updateVisibleLocations()
                }
            }
        }
    }
    
    private func updateVisibleLocations() {
        guard let positions = locationPositions else {
            visibleLocations.removeAll()
            return
        }
        visibleLocations = Set(positions.keys)
    }
    
    private func calculateLocationPositions(in geometry: GeometryProxy) -> [Int: CGPoint] {
        var positions: [Int: CGPoint] = [:]
        guard let currentScene = currentScene else { return positions }
        
        let margin: CGFloat = 60
        let availableWidth = geometry.size.width - margin * 2
        let availableHeight = geometry.size.height - margin * 2
        
        // Determine if we're using split view (has parent) or centered view
        let hasParent = parentScene != nil
        let leftColumnWidth = hasParent ? availableWidth * 0.6 : availableWidth
        let rightColumnWidth = hasParent ? availableWidth * 0.4 : 0
        
        // Calculate center points for both columns
        let leftCenter = CGPoint(
            x: margin + leftColumnWidth / 2,
            y: geometry.size.height / 2
        )
        
        let rightCenter = hasParent ? CGPoint(
            x: margin + leftColumnWidth + rightColumnWidth / 2,
            y: geometry.size.height / 2
        ) : .zero
        
        // Position current scene at left column center
        positions[currentScene.id] = leftCenter
        
        // Calculate radii for concentric circles
        let innerRadius = min(leftColumnWidth, availableHeight) * 0.3
        let outerRadius = min(leftColumnWidth, availableHeight) * 0.45
        
        // Position siblings in inner circle (clock positions)
        let siblings = Array(siblingScenes.prefix(10))
        if !siblings.isEmpty {
            let angleStep = 2 * CGFloat.pi / max(12, CGFloat(siblings.count))
            let startAngle = -CGFloat.pi / 2 // Start from 12 o'clock
            
            for (index, sibling) in siblings.enumerated() {
                let angle = startAngle + angleStep * CGFloat(index)
                positions[sibling.id] = CGPoint(
                    x: leftCenter.x + cos(angle) * innerRadius,
                    y: leftCenter.y + sin(angle) * innerRadius
                )
            }
        }
        
        // Position children in outer circle
        let children = Array(childScenes.prefix(10))
        if !children.isEmpty {
            let angleStep = 2 * CGFloat.pi / max(12, CGFloat(children.count))
            let startAngle = -CGFloat.pi / 2 // Start from 12 o'clock
            
            for (index, child) in children.enumerated() {
                let angle = startAngle + angleStep * CGFloat(index)
                positions[child.id] = CGPoint(
                    x: leftCenter.x + cos(angle) * outerRadius,
                    y: leftCenter.y + sin(angle) * outerRadius
                )
            }
        }
        
        // Handle parent and parent's siblings if they exist
        if let parent = parentScene {
            // Position parent at right column center
            positions[parent.id] = rightCenter
            
            // Position parent's siblings in circle around parent
            let parentSiblings = Array(LocationReader.getSiblingLocations(for: parent.id).prefix(10))
            if !parentSiblings.isEmpty {
                let parentCircleRadius = min(rightColumnWidth, availableHeight) * 0.35
                let angleStep = 2 * CGFloat.pi / max(12, CGFloat(parentSiblings.count))
                let startAngle = -CGFloat.pi / 2 // Start from 12 o'clock
                
                for (index, sibling) in parentSiblings.enumerated() {
                    let angle = startAngle + angleStep * CGFloat(index)
                    positions[sibling.id] = CGPoint(
                        x: rightCenter.x + cos(angle) * parentCircleRadius,
                        y: rightCenter.y + sin(angle) * parentCircleRadius
                    )
                }
            }
        }
        
        // Ensure all positions are within bounds
        return positions.mapValues { pos in
            CGPoint(
                x: pos.x.clamped(to: margin...geometry.size.width - margin),
                y: pos.y.clamped(to: margin...geometry.size.height - margin)
            )
        }
    }
    
    // Helper to determine if position update is needed
    private func shouldUpdatePositions(_ newPositions: [Int: CGPoint]) -> Bool {
        guard let currentPositions = locationPositions else { return true }
        
        // Check if the number of positions has changed
        if currentPositions.count != newPositions.count { return true }
        
        // Check if any position has changed significantly
        let threshold: CGFloat = 1.0
        for (id, newPos) in newPositions {
            guard let currentPos = currentPositions[id] else { return true }
            let distance = hypot(newPos.x - currentPos.x, newPos.y - currentPos.y)
            if distance > threshold { return true }
        }
        
        return false
    }
    
    func isLocationAccessible(_ scene: Scene) -> Bool {
        return (GameTimeService.shared.isNightTime || (AbilitiesSystem.shared.hasDayWalker && GameStateService.shared.player?.bloodMeter.currentBlood ?? 0 >= 70)) && !scene.isLocked
    }
    
    func getAvailableHideouts() -> [HidingCell] {
        return (currentScene?.sceneType.possibleHidingCells())!
    }
    
    func getGameStateService() -> GameStateService {
        return gameStateService
    }
    
    // MARK: - NPC Interaction Handling (Moved from MainSceneView)
    // Consider moving handleNPCAction here if appropriate
    func handleNPCAction(_ action: NPCAction) {
        // Ensure we're on main thread for UI operations
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleNPCAction(action)
            }
            return
        }
        
        print("MainSceneViewModel.handleNPCAction called with: \(action)")
        
        switch action {
        case .startConversation(let npc):
            // Validate NPC object integrity
            guard !npc.name.isEmpty, npc.id > 0 else {
                print("Error: Invalid NPC object in startConversation")
                return
            }
            print("Starting conversation with: \(npc.name)")
            // Просто обрабатываем событие для NPCManager
            npcManager.startConversation(with: npc)
        case .startIntimidation(let npc):
            guard !npc.name.isEmpty, npc.id > 0 else {
                print("Error: Invalid NPC object in startIntimidation")
                return
            }
            print("Starting intimidation with: \(npc.name)")
            showVampireGaze(npc: npc)
        case .feed(let npc):
            guard !npc.name.isEmpty, npc.id > 0 else {
                print("Error: Invalid NPC object in feed")
                return
            }
            print("Feeding on: \(npc.name)")
            feedOnCharacter(npc)
            npcManager.playerInteracted(with: npc)
        case .drain(let npc):
            guard !npc.name.isEmpty, npc.id > 0 else {
                print("Error: Invalid NPC object in drain")
                return
            }
            print("Draining: \(npc.name)")
            emptyBloodFromCharacter(npc)
            npcManager.playerInteracted(with: npc)
        case .investigate(let npc):
            guard !npc.name.isEmpty, npc.id > 0 else {
                print("Error: Invalid NPC object in investigate")
                return
            }
            print("Investigating: \(npc.name)")
            investigateNPC(npc)
            npcManager.select(with: npc)
        }
    }
    
    private func showVampireGaze(npc: NPC) {
        npcManager.selectedNPC = npc
        isShowingVampireGazeView = true
    }
    
    // Новый метод, который создает DialogueViewModel для разговора с NPC
    func createDialogueViewModel(for npc: NPC) -> DialogueViewModel? {
        guard let player = GameStateService.shared.player else { return nil }
        // Создаем DialogueViewModel
        return DialogueViewModel(npc: npc, player: player)
    }
    
    // MARK: - Button Visibility Methods
    
    func isAdvanceTimeButtonVisible() -> Bool {
        return true // Always visible
    }
    
    func isBlacksmithButtonVisible() -> Bool {
        return currentScene?.sceneType == .blacksmith
    }
    
    func isQuestJournalButtonVisible() -> Bool {
        return true // Always visible
    }
    
    func isNavigationButtonVisible() -> Bool {
        return !isPlayerArrested()
    }
    
    func isHidingCellButtonVisible() -> Bool {
        return !isPlayerArrested()
    }
    
    func isInvisibilityButtonVisible() -> Bool {
        guard let player = GameStateService.shared.player else { return false }
        return player.hiddenAt == .none && AbilitiesSystem.shared.hasInvisibility
    }
    
    func isReappearButtonVisible() -> Bool {
        guard let player = GameStateService.shared.player else { return false }
        return player.hiddenAt != .none && AbilitiesSystem.shared.hasInvisibility
    }
    
    func isWhisperButtonVisible() -> Bool {
        guard let player = GameStateService.shared.player else { return false }
        return player.hiddenAt != .none && AbilitiesSystem.shared.hasInvisibility && AbilitiesSystem.shared.hasWhisper
    }
    
    func isInventoryButtonVisible() -> Bool {
        return !isPlayerArrested()
    }
    
    func isAbilitiesButtonVisible() -> Bool {
        return true // Always visible
    }
    
    // Right side buttons
    func isLootButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return selectedNPC.currentActivity != .jailed && !isPlayerArrested() && !selectedNPC.isAlive
    }
    
    func isConversationButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return !selectedNPC.isUnknown && selectedNPC.isAlive && 
               selectedNPC.currentActivity != .sleep && 
               selectedNPC.currentActivity != .fleeing && 
               selectedNPC.currentActivity != .bathe
    }
    
    func isTradeButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return selectedNPC.isTradeAvailable() && 
               selectedNPC.currentActivity != .jailed && 
               !isPlayerArrested() &&
               selectedNPC.currentActivity != .sleep && 
               selectedNPC.currentActivity != .fleeing && 
               selectedNPC.currentActivity != .bathe
    }
    
    func isIntimidationButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return !selectedNPC.isUnknown && selectedNPC.isAlive
    }
    
    func isFeedButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return !selectedNPC.isVampire && 
               selectedNPC.currentActivity != .jailed && 
               !isPlayerArrested() && 
               FeedingService.shared.canFeed()
    }
    
    func isDrainButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return !selectedNPC.isVampire && 
               selectedNPC.currentActivity != .jailed && 
               !isPlayerArrested() && 
               FeedingService.shared.canFeed()
    }
    
    func isCombatButtonVisible() -> Bool {
        guard let selectedNPC = NPCInteractionManager.shared.selectedNPC else { return false }
        return selectedNPC.isAlive && !isPlayerArrested()
    }
    
    // Helper methods
    private func isPlayerArrested() -> Bool {
        guard let player = GameStateService.shared.player else { return false }
        return player.isArrested
    }
}

extension MainSceneViewModel {
    var allVisibleScenes: [Scene] {
        var scenes = [Scene]()
        
        // Add parent and limited parent's siblings
        if let parent = parentScene {
            scenes.append(parent)
            let parentSiblings = LocationReader.getSiblingLocations(for: parent.id)
            scenes.append(contentsOf: parentSiblings.prefix(10))
        }
        
        // Add limited siblings
        scenes.append(contentsOf: siblingScenes.prefix(10))
        
        // Add hub locations
        if let current = currentScene {
            let hubScenes = current.hubSceneIds.compactMap { id in
                try? LocationReader.getRuntimeLocation(by: id)
            }
            scenes.append(contentsOf: hubScenes)
        }
        
        // Add limited children
        scenes.append(contentsOf: childScenes.prefix(10))
        
        // Add current scene last to ensure it's rendered on top
        if let current = currentScene {
            scenes.append(current)
        }
        
        return scenes.uniqued()
    }
    
    func updateVisibleScenes() {
        guard let currentId = currentScene?.id else { return }
        
        // Update all relationships
        parentScene = LocationReader.getParentLocation(for: currentId)
        siblingScenes = LocationReader.getSiblingLocations(for: currentId)
        childScenes = LocationReader.getChildLocations(for: currentId)
    }
}
