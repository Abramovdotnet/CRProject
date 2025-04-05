import Foundation

struct DebugLogMessage: Identifiable, Equatable {
    let id = UUID()
    let timestamp: String
    let category: String
    let message: String
    
    static func == (lhs: DebugLogMessage, rhs: DebugLogMessage) -> Bool {
        lhs.id == rhs.id
    }
}

class DebugLogService {
    static let shared = DebugLogService()
    private var logMessages: [DebugLogMessage] = []
    private let maxLogCount = 1000
    
    private init() {}
    
    func log(_ message: String, category: String = "Debug") {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = DebugLogMessage(timestamp: timestamp, category: category, message: message)
        
        // Add to array
        logMessages.append(logMessage)
        
        // Trim if needed
        if logMessages.count > maxLogCount {
            logMessages.removeFirst(logMessages.count - maxLogCount)
        }
        
        // Print to console
        print("[\(timestamp)] [\(category)] \(message)")
    }
    
    func getCategories() -> [String] {
        return Array(Set(logMessages.map { $0.category })).sorted()
    }
    
    func getLogs() -> [DebugLogMessage] {
        return logMessages
    }
    
    func clearLogs() {
        logMessages.removeAll()
    }
} 