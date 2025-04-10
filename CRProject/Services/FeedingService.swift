import Foundation

class FeedingService: GameService {
    private let bloodService: BloodManagementService
    private let gameTime: GameTimeService
    private let vampireNatureRevealService: VampireNatureRevealService
    private let statisticsService: StatisticsService
    private let gameEventsBus: GameEventsBusService
    
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
    
    func feedOnCharacter(vampire: any Character, prey: any Character, amount: Float, in sceneId: Int) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        prey.isBeasy = true
        try bloodService.feed(vampire: vampire, prey: prey, amount: amount)
        
        var awarenessIncreaseValue: Float = 40.0;
        
        if prey.isIntimidated {
            prey.isIntimidated = false
            awarenessIncreaseValue -= 20
        }
        
        if prey.isSleeping {
            awarenessIncreaseValue -= 10
        }
        
        gameTime.advanceTime(hours: 1)
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(for: sceneId, amount: awarenessIncreaseValue)
        statisticsService.incrementFeedings()
        gameEventsBus.addDangerMessage(message: "Player consumed \(prey.name) blood.")
        
        if !prey.isAlive {
            gameEventsBus.addDangerMessage(message: "* I just killed \(prey.name)! Feel satisfied... *")
            // Double awareness increase if killing victim
            vampireNatureRevealService.increaseAwareness(for: sceneId, amount: awarenessIncreaseValue)
        }
    }
    
    func emptyBlood(vampire: any Character, prey: any Character, in sceneId: Int) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        let drainedBlood = try bloodService.emptyBlood(vampire: vampire, prey: prey)
        
        var awarenessIncreaseValue: Float = 70;
        
        if prey.isIntimidated {
            prey.isIntimidated = false
            awarenessIncreaseValue -= 25
        }
        
        if prey.isSleeping {
            awarenessIncreaseValue -= 25
        }
        
        gameTime.advanceTime(hours: 1)
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(for: sceneId, amount: awarenessIncreaseValue)
        statisticsService.incrementVictimsDrained()
        
        gameEventsBus.addDangerMessage(message: "Player drained \(prey.isUnknown ? "victim" : prey.name) empty.")
    }
}

enum FeedingError: Error {
    case invalidFeedingTarget(String)
}
