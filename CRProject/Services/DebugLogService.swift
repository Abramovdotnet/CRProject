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
    private let errorsFilePath: URL
    
    private init() {
        // Initialize errors file path in application's data directory
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = applicationSupportDirectory.appendingPathComponent("CRProject")
        let supportiveDirectory = appDirectory.appendingPathComponent("Supportive")
        errorsFilePath = supportiveDirectory.appendingPathComponent("Errors.txt")
        
        // Debug: Print the file path
        print("Debug: Application Support directory: \(applicationSupportDirectory.path)")
        print("Debug: Errors file path: \(errorsFilePath.path)")
        
        // Create app directory structure if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: supportiveDirectory, withIntermediateDirectories: true)
            print("Debug: Created directory structure at: \(supportiveDirectory.path)")
            
            // Create or clear Errors.txt
            try "".write(to: errorsFilePath, atomically: true, encoding: .utf8)
            print("Debug: Created/cleared Errors.txt at: \(errorsFilePath.path)")
            
            // Verify file exists and is readable
            if FileManager.default.fileExists(atPath: errorsFilePath.path) {
                print("Debug: Errors.txt exists at: \(errorsFilePath.path)")
                if let content = try? String(contentsOf: errorsFilePath, encoding: .utf8) {
                    print("Debug: Current Errors.txt content: \(content)")
                } else {
                    print("Debug: Could not read Errors.txt content")
                }
            } else {
                print("Debug: Errors.txt does not exist after creation attempt")
            }
        } catch {
            print("Debug: Failed to create directory or file: \(error)")
        }
    }
    
    private func appendToErrorsFile(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        // Get the caller file path
        let callerFile = #file
        let errorLine = "[\(timestamp)] [\(callerFile)] \(message)\n"
        
        do {
            if let fileHandle = try? FileHandle(forWritingTo: errorsFilePath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(errorLine.data(using: .utf8)!)
                fileHandle.closeFile()
                print("Debug: Appended to existing Errors.txt")
            } else {
                try errorLine.write(to: errorsFilePath, atomically: true, encoding: .utf8)
                print("Debug: Created new Errors.txt with content")
            }
        } catch {
            print("Debug: Failed to write to Errors.txt: \(error)")
        }
    }
    
    func readErrorLog() -> String? {
        do {
            let content = try String(contentsOf: errorsFilePath, encoding: .utf8)
            print("Debug: Successfully read Errors.txt")
            return content
        } catch {
            print("Debug: Failed to read Errors.txt: \(error)")
            return nil
        }
    }
    
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
        
        // If it's an error category, append to Errors.txt
        if category.lowercased() == "error" {
            appendToErrorsFile(message)
        }
    }
    
    func getCategories() -> [String] {
        return Array(Set(logMessages.map { $0.category })).sorted()
    }
    
    func getLogs() -> [DebugLogMessage] {
        return logMessages
    }
    
    func clearLogs() {
        logMessages.removeAll()
        // Clear Errors.txt file
        do {
            try "".write(to: errorsFilePath, atomically: true, encoding: .utf8)
            print("Debug: Cleared Errors.txt")
        } catch {
            print("Debug: Failed to clear Errors.txt: \(error)")
        }
    }
} 