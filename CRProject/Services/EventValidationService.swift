import Foundation

class EventValidationService {
    static let shared = EventValidationService()
    
    private init() {}
    
    func validateEvents(in events: [EventTemplate]) {
        DebugLogService.shared.log("Starting event validation...", category: "EventValidation")
        
        for event in events {
            // Validate professions
            for profession in event.requiredProfessions {
                if !isValidProfession(profession) {
                    DebugLogService.shared.log("⚠️ Invalid profession '\(profession)' in event '\(event.id)'", category: "EventValidation")
                }
            }
            
            // Validate location type
            if !isValidLocationType(event.locationType) {
                DebugLogService.shared.log("⚠️ Invalid locationType '\(event.locationType)' in event '\(event.id)'", category: "EventValidation")
            }
            
            // Validate scene type
            if !isValidSceneType(event.sceneType) {
                DebugLogService.shared.log("⚠️ Invalid sceneType '\(event.sceneType)' in event '\(event.id)'", category: "EventValidation")
            }
            
            // Validate time
            if !isValidTime(event.time) {
                DebugLogService.shared.log("⚠️ Invalid time '\(event.time)' in event '\(event.id)'", category: "EventValidation")
            }
            
            // Validate vampire presence
            if !isValidVampirePresence(event.vampirePresence) {
                DebugLogService.shared.log("⚠️ Invalid vampirePresence '\(event.vampirePresence)' in event '\(event.id)'", category: "EventValidation")
            }
            
            // Validate awareness levels
            if !isValidAwarenessRange(min: event.minAwareness, max: event.maxAwareness) {
                DebugLogService.shared.log("⚠️ Invalid awareness range [\(event.minAwareness)-\(event.maxAwareness)] in event '\(event.id)'", category: "EventValidation")
            }
            
            // Validate NPC counts
            if !isValidNPCRange(min: event.minNPCs, max: event.maxNPCs) {
                DebugLogService.shared.log("⚠️ Invalid NPC range [\(event.minNPCs)-\(event.maxNPCs)] in event '\(event.id)'", category: "EventValidation")
            }
            
            // Validate blood levels
            if !isValidBloodRange(min: event.minBloodLevel, max: event.maxBloodLevel) {
                DebugLogService.shared.log("⚠️ Invalid blood level range [\(event.minBloodLevel)-\(event.maxBloodLevel)] in event '\(event.id)'", category: "EventValidation")
            }
        }
        
        DebugLogService.shared.log("Event validation complete", category: "EventValidation")
    }
    
    private func isValidProfession(_ profession: String) -> Bool {
        return Profession.allCases.map { $0.rawValue }.contains(profession)
    }
    
    private func isValidLocationType(_ locationType: String) -> Bool {
        return SceneType.allCases.map { $0.rawValue }.contains(locationType)
    }
    
    private func isValidSceneType(_ sceneType: String) -> Bool {
        return SceneType.allCases.map { $0.rawValue }.contains(sceneType)
    }
    
    private func isValidTime(_ time: String) -> Bool {
        return ["day", "night"].contains(time)
    }
    
    private func isValidVampirePresence(_ presence: String) -> Bool {
        return ["required", "forbidden", "optional"].contains(presence)
    }
    
    private func isValidAwarenessRange(min: Int, max: Int) -> Bool {
        return min >= 0 && max <= 100 && min <= max
    }
    
    private func isValidNPCRange(min: Int, max: Int) -> Bool {
        return min >= 0 && max <= 50 && min <= max // Assuming 50 is a reasonable max for NPCs in one location
    }
    
    private func isValidBloodRange(min: Int, max: Int) -> Bool {
        return min >= 0 && max <= 100 && min <= max
    }
} 