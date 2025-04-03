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
    
    func feedOnCharacter(vampire: any Character, prey: any Character, amount: Float, in sceneId: UUID) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        try bloodService.feed(vampire: vampire, prey: prey, amount: amount)
        gameTime.advanceTime(hours: 1)
        statisticsService.incrementFeedings()
        
        // Increase awareness in the scene where feeding occurred
        vampireNatureRevealService.increaseAwareness(for: sceneId, amount: 10.0)
        
        gameEventsBus.addEventMessage("Player consumed \(prey.name) blood.")
        
        if !prey.isAlive {
            gameEventsBus.addWarningMessage("* I just killed \(prey.name)! Feel satisfied... *")
        }
    }
    
    func emptyBlood(vampire: any Character, prey: any Character, in sceneId: UUID) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        let drainedBlood = try bloodService.emptyBlood(vampire: vampire, prey: prey)
        gameTime.advanceTime(hours:1)
        statisticsService.incrementVictimsDrained()
        
        // Increase awareness more significantly when emptying blood
        vampireNatureRevealService.increaseAwareness(for: sceneId, amount: 30.0)
        
        gameEventsBus.addEventMessage("Player drained \(prey.isUnknown ? "victim" : prey.name) empty.")
    }
}

enum FeedingError: Error {
    case invalidFeedingTarget(String)
}
