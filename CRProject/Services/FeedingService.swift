import Foundation

class FeedingService: GameService {
    private let bloodService: BloodManagementService
    private let gameTime: GameTimeService
    private let vampireNatureRevealService: VampireNatureRevealService
    private let statisticsService: StatisticsService
    private let gameEventsBus: GameEventsBusService
    
    static var shared: FeedingService = DependencyManager.shared.resolve()
    
    init(bloodService: BloodManagementService = DependencyManager.shared.resolve(),
         gameTime: GameTimeService = DependencyManager.shared.resolve(),
         vampireNatureRevealService: VampireNatureRevealService = DependencyManager.shared.resolve(),
         statisticsService: StatisticsService = DependencyManager.shared.resolve(),
         gameEventsBus: GameEventsBusService = DependencyManager.shared.resolve()) {
        self.bloodService = bloodService
        self.gameTime = gameTime
        self.vampireNatureRevealService = vampireNatureRevealService
        self.statisticsService = statisticsService
        self.gameEventsBus = gameEventsBus
    }
    
    func canFeed(vampire: any Character, prey: any Character) -> Bool {
        guard vampire.isVampire else { return false }
        guard !prey.isVampire else { return false }
        return prey.bloodMeter.bloodPercentage > 0
    }
    
    func feedOnCharacter(vampire: Player, prey: NPC, amount: Float, in sceneId: Int) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        try bloodService.feed(vampire: vampire, prey: prey, amount: amount)
        
        var awarenessIncreaseValue: Float = 50.0;
        
        if prey.currentActivity == .seductedByPlayer || prey.currentActivity == .allyingPlayer {
            awarenessIncreaseValue -= 40
        }
        
        if prey.currentActivity == .sleep {
            awarenessIncreaseValue -= 20
        }
        
        if vampire.desiredVictim.isDesiredVictim(npc: prey){
            vampire.bloodMeter.addBlood(100.0)
            vampire.desiredVictim.updateDesiredVictim()
            
            gameEventsBus.addDangerMessage(message: "Player consumed DESIRED victims blood.")
        }
        
        setWitnessesIfExists(sceneId: sceneId)
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(for: sceneId, amount: awarenessIncreaseValue)
        statisticsService.incrementFeedings()
        gameEventsBus.addDangerMessage(message: "Player consumed \(prey.name) blood.")
        
        if !prey.isAlive {
            gameEventsBus.addDangerMessage(message: "* I just killed \(prey.name)! Feel satisfied... *")
            // Double awareness increase if killing victim
            vampireNatureRevealService.increaseAwareness(for: sceneId, amount: awarenessIncreaseValue)
        }
        
        NPCInteractionManager.shared.playerInteracted(with: prey)
        
        gameTime.advanceTime()
    }
    
    func emptyBlood(vampire: any Character, prey: NPC, in sceneId: Int) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        let drainedBlood = try bloodService.emptyBlood(vampire: vampire, prey: prey)
        
        var awarenessIncreaseValue: Float = 70;
        
        if prey.currentActivity == .seductedByPlayer || prey.currentActivity == .allyingPlayer {
            awarenessIncreaseValue -= 25
        } else {
            prey.decreasePlayerRelationship(with: 100)
        }
        
        if prey.currentActivity == .sleep {
            awarenessIncreaseValue -= 25
        }
        
        setWitnessesIfExists(sceneId: sceneId)
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(for: sceneId, amount: awarenessIncreaseValue)
        statisticsService.incrementVictimsDrained()
        
        gameEventsBus.addDangerMessage(message: "Player drained \(prey.isUnknown ? "victim" : prey.name) empty.")
        
        NPCInteractionManager.shared.playerInteracted(with: prey)
        
        gameTime.advanceTime()
    }
    
    func setWitnessesIfExists(sceneId: Int) {
        var scene = try? LocationReader.getRuntimeLocation(by: sceneId)
        
        var npcs = scene?.getNPCs()
            .filter( { $0.isAlive && $0.currentActivity != .sleep && $0.currentActivity != .allyingPlayer && $0.currentActivity != .seductedByPlayer })
        
        guard var npcs else { return }
        guard let player = GameStateService.shared.player else { return }
        
        if player.hiddenAt != .none {
            npcs = npcs.filter( { $0.currentActivity == .followingPlayer })
        }
        
        if npcs.count > 0 {
            for npc in npcs {
                npc.isVampireAttackWitness = true
                npc.isBeasyByPlayerAction = true
                npc.decreasePlayerRelationship(with: 100)
            }
        }
    }
}

enum FeedingError: Error {
    case invalidFeedingTarget(String)
}
