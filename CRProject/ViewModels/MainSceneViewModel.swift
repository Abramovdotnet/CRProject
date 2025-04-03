import Foundation
import Combine

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
            let initialScene = try LocationReader.getLocation(by: UUID(uuidString: "DF0B418F-0E65-4109-8944-66622EF59191")!) // East field Market
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
        
        npcs = NPCReader.getRandomNPCs(count: Int.random(in: 1...10))
        
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
        
        do {
            parentScene = try LocationReader.getParentLocation(for: locationId)
            childScenes = try LocationReader.getChildLocations(for: locationId)
            siblingScenes = try LocationReader.getSiblingLocations(for: locationId)
        } catch {
            print("Error updating related locations: \(error)")
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
} 
