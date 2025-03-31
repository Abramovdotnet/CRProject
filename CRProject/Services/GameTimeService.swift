import Foundation

class GameTime: GameService {
    private(set) var currentHour: Int = 18 // Start at 6 PM
    private(set) var currentDay: Int = 1
    var isNightTime: Bool { currentHour >= 20 || currentHour < 6 }
    
    // Events
    var onNewDay: (() -> Void)?
    var onSunrise: (() -> Void)?
    var onSunset: (() -> Void)?
    
    func advanceTime(hours: Int) {
        currentHour += hours
        
        // Handle day progression
        if currentHour >= 24 {
            currentHour %= 24
            currentDay += 1
            onNewDay?()
        }
        
        // Check for time-based events
        checkTimeEvents()
    }
    
    private func checkTimeEvents() {
        if currentHour == 6 {
            onSunrise?()
        }
        if currentHour == 20 {
            onSunset?()
        }
    }
    
    var description: String {
        return String(format: "%02d:00 (Day %d) - %@",
                     currentHour,
                     currentDay,
                     isNightTime ? "Night" : "Day")
    }
}
