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
        
        prey.isBeasyByPlayerAction = true
        
        try bloodService.feed(vampire: vampire, prey: prey, amount: amount)
        
        var awarenessIncreaseValue: Float = 90.0;
        
        if prey.currentActivity == .seductedByPlayer || prey.currentActivity == .allyingPlayer {
            awarenessIncreaseValue -= 86
            vampire.bloodMeter.addBlood(10)
        }
        
        if prey.currentActivity == .sleep {
            awarenessIncreaseValue -= 88
            
            StatisticsService.shared.increasefeedingsOverSleepingVictims()
        }
        
        if vampire.desiredVictim.isDesiredVictim(npc: prey){
            vampire.bloodMeter.addBlood(amount * 3)
            vampire.desiredVictim.updateDesiredVictim()
            
            StatisticsService.shared.increasefeedingsOverDesiredVictims()
            
            gameEventsBus.addDangerMessage(message: "Player consumed DESIRED victims blood.")
        }
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(amount: awarenessIncreaseValue)
        statisticsService.incrementFeedings()
        gameEventsBus.addDangerMessage(message: "Player consumed \(prey.name) blood.")
        
        if !prey.isAlive {
            gameEventsBus.addWarningMessage("* I just killed \(prey.name)! Feel satisfied... *")
            // Double awareness increase if killing victim
            vampireNatureRevealService.increaseAwareness(amount: awarenessIncreaseValue)
        }
        
        NPCInteractionManager.shared.playerInteracted(with: prey)
        
        setWitnessesIfExists(sceneId: sceneId)
        
        gameTime.advanceTime()
    }
    
    func consumeFood(vampire: Player, food: Item) {
        if food.isConsumable {
            // If player has Masquerade ability, consuming food reduces awareness twice as much
            let decreaseAmount: Float = AbilitiesSystem.shared.hasMasquerade ? 2.0 : 1.0
            vampireNatureRevealService.decreaseAwareness(amount: decreaseAmount)
            vampire.bloodMeter.useBlood(1)
            
            ItemsManagementService.shared.removeItem(item: food, from: vampire)
            StatisticsService.shared.increaseFoodConsumed()
        }
    }
    
    func emptyBlood(vampire: any Character, prey: NPC, in sceneId: Int) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        try bloodService.emptyBlood(vampire: vampire, prey: prey)
        
        var awarenessIncreaseValue: Float = 30;
        
        if AbilitiesSystem.shared.hasSonOfDracula {
            vampire.bloodMeter.increaseMaxBlood(1)
        }
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(amount: awarenessIncreaseValue)
        statisticsService.incrementVictimsDrained()
        
        gameEventsBus.addDangerMessage(message: "Player drained \(prey.isUnknown ? "victim" : prey.name) empty.")
        
        NPCInteractionManager.shared.playerInteracted(with: prey)
        
        setWitnessesIfExists(sceneId: sceneId)
        
        gameTime.advanceTime()
    }
    
    func setWitnessesIfExists(sceneId: Int) {
        let scene = try? LocationReader.getRuntimeLocation(by: sceneId)
        
        let npcs = scene?.getNPCs()
            .filter( { $0.isAlive && $0.currentActivity != .allyingPlayer && $0.currentActivity != .seductedByPlayer && $0.currentActivity != .sleep })
        
        guard var npcs else { return }
        guard let player = GameStateService.shared.player else { return }
        
        if player.hiddenAt != .none {
            npcs = npcs.filter( { $0.currentActivity == .followingPlayer })
        }
        
        if npcs.count > 0 {
            vampireNatureRevealService.increaseAwareness(amount: 90)
            for npc in npcs {
                npc.isVampireAttackWitness = true
                npc.isBeasyByPlayerAction = true
                npc.decreasePlayerRelationship(with: 100)
            }

            gameEventsBus.addWarningMessage("* \(npcs.count) characters just saw how i consumed blood! *")
        }
    }
}

enum FeedingError: Error {
    case invalidFeedingTarget(String)
}
