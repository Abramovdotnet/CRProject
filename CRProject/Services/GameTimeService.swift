import Foundation
import Combine

extension Notification.Name {
    static let timeAdvanced = Notification.Name("timeAdvanced")
}

class GameTimeService: GameService {
    @Published private(set) var currentDay: Int = 0
    @Published private(set) var currentHour: Int = 0
    @Published private(set) var currentTime: Date
    @Published private(set) var isNightTime: Bool = false
    
    private let statisticsService: StatisticsService
    
    init(statisticsService: StatisticsService = DependencyManager.shared.resolve()) {
        self.statisticsService = statisticsService
        self.currentTime = Date()
        self.currentHour = 7
        updateNightTimeStatus()
    }
    
    var description: String {
        return "Day \(currentDay), \(currentHour):00"
    }
    
    func advanceTime(hours: Int = 1) {
        let oldDay = currentDay
        currentHour = (currentHour + hours) % 24
        currentDay += (currentHour < hours ? 1 : 0)
        
        if currentDay > oldDay {
            statisticsService.incrementDaysSurvived()
        }
        
        currentTime = Calendar.current.date(byAdding: .hour, value: hours, to: currentTime) ?? currentTime
        updateNightTimeStatus()
        NotificationCenter.default.post(name: .timeAdvanced, object: nil)
    }
    
    private func updateNightTimeStatus() {
        isNightTime = self.currentHour >= 20 || self.currentHour < 6
    }
}
