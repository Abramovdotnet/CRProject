import Foundation
import Combine

class GameTimeService: GameService {
    @Published private(set) var currentDay: Int = 0
    @Published private(set) var currentHour: Int = 0
    
    private let statisticsService: StatisticsService
    
    init(statisticsService: StatisticsService = DependencyManager.shared.resolve()) {
        self.statisticsService = statisticsService
    }
    
    var isNightTime: Bool {
        return currentHour >= 20 || currentHour < 6
    }
    
    var description: String {
        return "Day \(currentDay), \(currentHour):00"
    }
    
    func advanceTime(hours: Int) {
        let oldDay = currentDay
        currentHour = (currentHour + hours) % 24
        currentDay += (currentHour < hours ? 1 : 0)
        
        if currentDay > oldDay {
            statisticsService.incrementDaysSurvived()
        }
    }
}
