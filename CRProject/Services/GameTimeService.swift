import Foundation
import Combine

extension Notification.Name {
    static let timeAdvanced = Notification.Name("timeAdvanced")
    static let safeTimeAdvanced = Notification.Name("safeTimeAdvanced")
    static let nightAppears = Notification.Name("nightAppears")
    static let dayAppears = Notification.Name("dayAppears")
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
    func advanceTimeSafe(hours: Int = 1) {
        let oldDay = currentDay
        currentHour = (currentHour + hours) % 24
        currentDay += (currentHour < hours ? 1 : 0)
        
        if currentDay > oldDay {
            statisticsService.incrementDaysSurvived()
        }
        
        currentTime = Calendar.current.date(byAdding: .hour, value: hours, to: currentTime) ?? currentTime
        updateNightTimeStatus()
        NotificationCenter.default.post(name: .safeTimeAdvanced, object: nil)
    }
    
    private func updateNightTimeStatus() {
        let currentValue = isNightTime
        
        isNightTime = self.currentHour >= 20 || self.currentHour < 6
        
        if currentValue != isNightTime {
            if isNightTime {
                NotificationCenter.default.post(name: .nightAppears, object: nil)
            } else {
                NotificationCenter.default.post(name: .dayAppears, object: nil)
            }
        }
    }
}
