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
    @Published var isNight: Bool = false
    @Published var isGameEnd: Bool = false
    @Published var sceneSplit: Int = 0
    @Published private(set) var locationPositions: [UUID: CGPoint]?
    @Published private(set) var visibleLocations: Set<UUID> = []
    
    private var cancellables = Set<AnyCancellable>()
    let gameStateService: GameStateService
    private let vampireNatureRevealService: VampireNatureRevealService
    private let feedingService: FeedingService
    private let investigationService: InvestigationService
    private let bloodManagementService: BloodManagementService
    private let gameTime: GameTimeService
    
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
        gameStateService.setPlayer(player)
        
        updatePlayerBloodPercentage()
        
        // Create initial scene using LocationReader
        do {
            guard let initialSceneId = UUID(uuidString: "8a9b0c1d-b2c3-4d5e-6f7a-8b9c0d1e2f3a") else {
                print("Error: Invalid initial scene ID")
                return
            }
            let initialScene = try LocationReader.getLocation(by: initialSceneId)
            try gameStateService.changeLocation(to: initialScene.id)
            
            // Set default awareness to 0
            vampireNatureRevealService.decreaseAwareness(for: initialScene.id, amount: 100)
            respawnNPCs()
        } catch {
            print("Error creating initial scene: \(error)")
        }
        
        // Subscribe to scene changes
        gameStateService.$currentScene
            .sink { [weak self] scene in
                self?.currentScene = scene
                self?.updateRelatedLocations(for: scene?.id)
                self?.respawnNPCs()
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
        
        // Subscribe to day changes
        gameTime.$currentDay
            .assign(to: &$currentDay)
            
        // Subscribe to hour changes
        gameTime.$currentHour
            .assign(to: &$currentHour)
            
        // Subscribe to night/day changes
        gameTime.$isNightTime
            .sink { [weak self] isNight in
                self?.isNight = isNight
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Methods
    func navigateToParent() {
        guard let parentScene = parentScene else { return }
        try? gameStateService.changeLocation(to: parentScene.id)
        currentScene = gameStateService.currentScene
        updateSceneAwareness()
        updatePlayerBloodPercentage()
    }
    
    func navigateToChild(_ scene: Scene) {
        try? gameStateService.changeLocation(to: scene.id)
        currentScene = gameStateService.currentScene
        updateSceneAwareness()
        updatePlayerBloodPercentage()
    }
    
    func navigateToSibling(_ scene: Scene) {
        try? gameStateService.changeLocation(to: scene.id)
        currentScene = gameStateService.currentScene
        updateSceneAwareness()
        updatePlayerBloodPercentage()
    }
    
    // MARK: - NPC Management
    func respawnNPCs() {
        print("Respawning NPCs...")
        npcs = []
        let count = Int.random(in: 2...4)
        print("Generating \(count) NPCs")
        
        npcs = NPCReader.getRandomNPCs(count: Int.random(in: 1...30))
        
        for npc in npcs {
            print("Created NPC: \(npc.name)")
        }
        
        print("Total NPCs: \(npcs.count)")
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
        vampireNatureRevealService.decreaseAwareness(for: currentScene?.id ?? UUID(), amount: 100)
        updateSceneAwareness()
    }
    
    // MARK: - Blood Management
    func feedOnCharacter(_ npc: NPC) {
        guard let player = gameStateService.getPlayer(),
              feedingService.canFeed(vampire: player, prey: npc) else {
            return
        }
        let sceneId = currentScene?.id ?? UUID()
        do {
            try feedingService.feedOnCharacter(vampire: player, prey: npc, amount: 30, in: sceneId)
            updatePlayerBloodPercentage()
            vampireNatureRevealService.increaseAwareness(for: currentScene?.id ?? UUID(), amount: 20)
            updateSceneAwareness()
            print(sceneAwareness)
        } catch {
            print("Error feeding on character: \(error)")
        }
    }
    
    func emptyBloodFromCharacter(_ npc: NPC) {
        guard let player = gameStateService.getPlayer(),
              feedingService.canFeed(vampire: player, prey: npc) else {
            return
        }
        do {
            try feedingService.emptyBlood(vampire: player, prey: npc, in: currentScene?.id ?? UUID())
            updatePlayerBloodPercentage()
            updateSceneAwareness()
            print("Blood emptied")
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
    private func updateRelatedLocations(for locationId: UUID?) {
        guard let locationId = locationId else { return }
        
        print("Updating related locations for ID: \(locationId)")
        
        // Get parent location
        parentScene = LocationReader.getParentLocation(for: locationId)
        print("Parent scene: \(parentScene?.name ?? "None")")
        
        // Get child locations
        childScenes = LocationReader.getChildLocations(for: locationId)
        print("Child scenes count: \(childScenes.count)")
        for scene in childScenes {
            print("Child scene: \(scene.name)")
        }
        
        // Get sibling locations
        siblingScenes = LocationReader.getSiblingLocations(for: locationId)
        print("Sibling scenes count: \(siblingScenes.count)")
        for scene in siblingScenes {
            print("Sibling scene: \(scene.name)")
        }
    }
    
    private func updatePlayerBloodPercentage() {
        guard let player = gameStateService.getPlayer() else { return }
        self.playerBloodPercentage = bloodManagementService.getBloodPercentage(of: player)
    }
    
    private func updateSceneAwareness() {
        guard let currentSceneId = currentScene?.id else { return }
        sceneAwareness = vampireNatureRevealService.getAwareness(for: currentSceneId)
    }
    
    func getLocationAwareness(_ scene: Scene) -> Float {
        return vampireNatureRevealService.getAwareness(for: scene.id)
    }
    
    var isAwarenessSafe: Bool {
        guard let currentSceneId = currentScene?.id else { return true }
        return vampireNatureRevealService.getAwareness(for: currentSceneId) < 100
    }
    
    func skipTimeToNight() {
        while !gameTime.isNightTime {
            gameTime.advanceTimeSafe()
        }
    }
    
    func updateLocationPositions(in geometry: GeometryProxy) {
        locationPositions = calculateLocationPositions(in: geometry)
        updateVisibleLocations()
    }
    
    private func updateVisibleLocations() {
        guard let positions = locationPositions else { return }
        visibleLocations = Set(positions.keys)
    }
    
    func isLocationAccessible(_ scene: Scene) -> Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        let bloodCost: Float = 5 // Standard blood cost for movement
        let currentBlood = Float(player.bloodMeter.currentBlood)
        let bloodAfterTravel = currentBlood - bloodCost
        return bloodAfterTravel >= 10 // 10% threshold
    }
}

extension MainSceneViewModel {
    var allVisibleScenes: [Scene] {
        var scenes = [Scene]()
        
        // 1. Add current scene if exists
        if let current = currentScene {
            scenes.append(current)
        }
        
        // 2. Add parent scene if exists
        if let parent = parentScene {
            scenes.append(parent)
        }
        
        // 3. Add all sibling scenes
        scenes.append(contentsOf: siblingScenes)
        
        // 4. Add all child scenes
        scenes.append(contentsOf: childScenes)
        
        // 5. Add "cousin" scenes (siblings of parent)
        if let parent = parentScene,
           let _ = try? LocationReader.getParentLocation(for: parent.id) {
            let auntsUncles = LocationReader.getSiblingLocations(for: parent.id)
            scenes.append(contentsOf: auntsUncles)
            
            // 6. Add second-level children (children of siblings)
            for sibling in siblingScenes {
                let niecesNephews = LocationReader.getChildLocations(for: sibling.id)
                scenes.append(contentsOf: niecesNephews)
            }
        }
        
        // Remove duplicates and limit to 15 scenes max
        return Array(Set(scenes)).prefix(15).map { $0 }
    }
    
    func updateVisibleScenes() {
        guard let currentId = currentScene?.id else { return }
        
        // Update all relationships
        parentScene = LocationReader.getParentLocation(for: currentId)
        siblingScenes = LocationReader.getSiblingLocations(for: currentId)
        childScenes = LocationReader.getChildLocations(for: currentId)
    }
}
