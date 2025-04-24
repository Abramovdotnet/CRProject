import Foundation
import Combine

class StatisticsService: GameService {
    @Published private(set) var daysSurvived: Int = 0
    @Published private(set) var feedings: Int = 0
    @Published private(set) var victimsDrained: Int = 0
    @Published private(set) var peopleKilled: Int = 0
    @Published private(set) var investigations: Int = 0
    @Published private(set) var peopleSeducted: Int = 0
    @Published private(set) var peopleIntimidated: Int = 0
    @Published private(set) var bartersCompleted: Int = 0
    
    static let shared: StatisticsService = DependencyManager.shared.resolve()
    
    func increasePeopleSeducted() {
        peopleSeducted += 1
    }
    
    func increasePeopleIntimidated() {
        peopleIntimidated += 1
    }
    
    func increaseBartersCompleted() {
        bartersCompleted += 1
    }
    
    func incrementDaysSurvived() {
        daysSurvived += 1
    }
    
    func incrementFeedings() {
        feedings += 1
    }
    
    func incrementVictimsDrained() {
        victimsDrained += 1
    }
    
    func incrementPeopleKilled() {
        peopleKilled += 1
    }
    
    func incrementInvestigations() {
        investigations += 1
    }
    
    func reset() {
        daysSurvived = 0
        feedings = 0
        victimsDrained = 0
        peopleKilled = 0
        investigations = 0
    }
} 
