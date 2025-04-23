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
    @Published var desiredProfession: Profession?
    @Published var desiredSex: Sex?
    @Published var desiredAge: String?
    @Published var desiredMorality: Morality?
    @Published var currentDay: Int = 1
    @Published var currentHour: Int = 0
    @Published var isNight: Bool = false
    @Published var isGameEnd: Bool = false
    @Published var sceneSplit: Int = 0
    @Published var selectedItemIndex: Int = 0
    @Published private(set) var locationPositions: [Int: CGPoint]?
    @Published private(set) var visibleLocations: Set<Int> = []
    @Published var isDebugOverlayVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    let gameStateService: GameStateService
    private let vampireNatureRevealService: VampireNatureRevealService
    private let feedingService: FeedingService
    private let investigationService: InvestigationService
    private let bloodManagementService: BloodManagementService
    private let gameTime: GameTimeService
    
    @StateObject private var npcManager = NPCInteractionManager.shared
    
    var playerName: String {
        gameStateService.getPlayer()?.name ?? "Unknown"
    }
    
    var playerStatus: String {
        guard let player = gameStateService.getPlayer() else { return "Unknown" }
        return player.isAlive ? "Alive" : "Dead"
    }
    
    func adjustScene()
    {
        sceneSplit = sceneSplit + 1
    }
    
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
        let player = NPCGenerator.createPlayer()
        player.coins.add(1000)
        gameStateService.setPlayer(player)
        ItemsManagementService.shared.giveItem(itemId: 1, to: player)
        
        updatePlayerBloodPercentage()
        resetDesires()
        
        // Subscribe to scene changes
        gameStateService.$currentScene
            .sink { [weak self] scene in
                self?.currentScene = scene
                self?.updateRelatedLocations(for: scene?.id ?? 0)
                // Update NPCs when scene changes
                if let npcs = scene?.getNPCs() {
                    self?.npcs = npcs
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to scene character changes
        NotificationCenter.default.publisher(for: .sceneCharactersChanged)
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
        
        // Subscribe to night/day changes
        gameTime.$isNightTime
            .sink { [weak self] isNight in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.isNight = isNight
                }
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
        
        // Subscribe to blood changes
        NotificationCenter.default.publisher(for: .bloodPercentageChanged)
            .sink { [weak self] _ in
                self?.updatePlayerBloodPercentage()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .exposed)
            .sink { [weak self] _ in
                self?.endGame()
            }
            .store(in: &cancellables)
            
        // Initial updates
        updatePlayerBloodPercentage()
        updateSceneAwareness()
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
            updatePlayerBloodPercentage()
        }
    }
    
    func navigateToChild(_ scene: Scene) {
        // Store current positions for animation
        let oldPositions = locationPositions
        
        try? gameStateService.changeLocation(to: scene.id)
        currentScene = gameStateService.currentScene
        
        // Trigger position update with animation
        withAnimation(.easeInOut(duration: 0.6)) {
            if let oldPos = oldPositions {
                locationPositions = oldPos
            }
            updateSceneAwareness()
            updatePlayerBloodPercentage()
        }
    }
    
    func navigateToSibling(_ scene: Scene) {
        // Store current positions for animation
        let oldPositions = locationPositions
        
        try? gameStateService.changeLocation(to: scene.id)
        currentScene = gameStateService.currentScene
        
        // Trigger position update with animation
        withAnimation(.easeInOut(duration: 0.6)) {
            if let oldPos = oldPositions {
                locationPositions = oldPos
            }
            updateSceneAwareness()
            updatePlayerBloodPercentage()
        }
    }
    
    // MARK: - NPC Management
    func respawnNPCs() {
        DebugLogService.shared.log("Respawning NPCs...", category: "NPC")
        npcs = []
        let count = Int.random(in: 2...4)
        DebugLogService.shared.log("Generating \(count) NPCs", category: "NPC")
        
        npcs = NPCReader.getRandomNPCs(count: Int.random(in: 1...30))
        
        for npc in npcs {
            DebugLogService.shared.log("Created NPC: \(npc.name)", category: "NPC")
        }
        
        gameStateService.currentScene?.setCharacters(npcs)
        
        DebugLogService.shared.log("Total NPCs: \(npcs.count)", category: "NPC")
    }
    
    func endGame(){
        isGameEnd = true
    }
    
    func investigateNPC(_ npc: NPC) {
        guard let player = gameStateService.getPlayer(),
              investigationService.canInvestigate(inspector: player, investigationObject: npc) else {
            return
        }
        investigationService.investigate(inspector: player, investigationObject: npc)
        updateSceneAwareness()
        updatePlayerBloodPercentage()
    }
    
    func resetAwareness() {
        vampireNatureRevealService.decreaseAwareness(amount: 100)
        updateSceneAwareness()
    }
    
    func resetBloodPool() {
        guard let player = gameStateService.getPlayer() else { return }
        
        player.bloodMeter.currentBlood = 100
        updatePlayerBloodPercentage()
    }
    
    func resetDesires() {
        GameStateService.shared.player?.desiredVictim.updateDesiredVictim()
        
        guard let desires = GameStateService.shared.player?.desiredVictim else { return }
        
        desiredAge = desires.desiredAgeRange?.rangeDescription
        desiredSex = desires.desiredSex
        desiredMorality = desires.desiredMorality
        desiredProfession = desires.desiredProfession
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
            updatePlayerBloodPercentage()
            updateSceneAwareness()

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
            updatePlayerBloodPercentage()
            updateSceneAwareness()
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
        
        // Get sibling locations
        siblingScenes = LocationReader.getSiblingLocations(for: locationId)
        DebugLogService.shared.log("DEBUG: Sibling scenes count: \(siblingScenes.count)", category: "Debug")
    }
    
    func updatePlayerBloodPercentage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            guard let player = gameStateService.getPlayer() else { return }
            self.playerBloodPercentage = bloodManagementService.getBloodPercentage(of: player)
        }
    }
    
    func updateSceneAwareness() {
        withAnimation(.easeInOut(duration: 0.3)) {
            guard let currentSceneId = currentScene?.id else { return }
            sceneAwareness = vampireNatureRevealService.getAwareness()
        }
    }
    
    func getLocationAwareness(_ scene: Scene) -> Float {
        return vampireNatureRevealService.getAwareness()
    }
    
    func canSkipTimeSafe() -> Bool {
        let canSkipToNight = [.tavern, .brothel, .cemetery, .house ,.warehouse]
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
            updatePlayerBloodPercentage()
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
        return gameTime.isNightTime && !scene.isLocked
    }
    
    func toggleDebugOverlay() {
        isDebugOverlayVisible.toggle()
        DebugLogService.shared.log("Debug overlay \(isDebugOverlayVisible ? "shown" : "hidden")", category: "Debug")
    }
    
    func getAvailableHideouts() -> [HidingCell] {
        return (currentScene?.sceneType.possibleHidingCells())!
    }
    
    func getPlayer() -> Player {
        return gameStateService.getPlayer()!
    }
    
    func getGameStateService() -> GameStateService {
        return gameStateService
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
