import Foundation

class FeedingService: GameService {
    private let bloodService: BloodManagementService
    private let gameTime: GameTime
    
    init(bloodService: BloodManagementService = DependencyManager.shared.resolve(),
         gameTime: GameTime = DependencyManager.shared.resolve()) {
        self.bloodService = bloodService
        self.gameTime = gameTime
    }
    
    func canFeed(vampire: any Character, prey: any Character) -> Bool {
        guard vampire.isVampire else { return false }
        guard !prey.isVampire else { return false }
        return prey.bloodMeter.bloodPercentage > 0
    }
    
    func feedOnCharacter(vampire: any Character, prey: any Character, amount: Float) throws {
        guard canFeed(vampire: vampire, prey: prey) else {
            throw FeedingError.invalidFeedingTarget("Cannot feed on this character")
        }
        
        try bloodService.feed(vampire: vampire, prey: prey, amount: amount)
        gameTime.advanceTime(hours: 1)
    }
}

enum FeedingError: Error {
    case invalidFeedingTarget(String)
}
