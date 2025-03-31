import Foundation

class FeedingService: GameService {
    private var _hungerLevel: Float = 0.0
    private var _lastFeedingTime: TimeInterval = 0.0
    private let maxHungerLevel: Float = 100.0
    private let bloodService: BloodManagementService
    
    var hungerLevel: Float {
        return _hungerLevel
    }
    
    var timeSinceLastFeeding: TimeInterval {
        return Date().timeIntervalSince1970 - _lastFeedingTime
    }
    
    init(bloodService: BloodManagementService = DependencyManager.shared.resolve()) {
        self.bloodService = bloodService
    }
    
    func feed(amount: Float) {
        _hungerLevel = min(_hungerLevel + amount, maxHungerLevel)
        _lastFeedingTime = Date().timeIntervalSince1970
    }
    
    func updateHunger(deltaTime: Float) {
        _hungerLevel = max(0, _hungerLevel - deltaTime)
    }
    
    func isHungry() -> Bool {
        return _hungerLevel < maxHungerLevel * 0.3
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
        feed(amount: amount)
    }
}

enum FeedingError: Error {
    case invalidFeedingTarget(String)
}
