import Foundation

class InvestigationService: GameService {
    private let bloodService: BloodManagementService
    private let gameTime: GameTimeService
    private let statisticsService: StatisticsService
    private let gameEventsBus: GameEventsBusService
    
    init(bloodService: BloodManagementService = DependencyManager.shared.resolve(),
         gameTime: GameTimeService = DependencyManager.shared.resolve(),
         statisticsService: StatisticsService = DependencyManager.shared.resolve(),
         gameEventsBus: GameEventsBusService = DependencyManager.shared.resolve()) {
        self.bloodService = bloodService
        self.gameTime = gameTime
        self.statisticsService = statisticsService
        self.gameEventsBus = gameEventsBus
    }
    
    func canInvestigate(inspector: any Character, investigationObject: any Character) -> Bool {
        // Check if object is already investigated
        guard investigationObject.isUnknown else { return false }
        
        // For vampires, check if they have enough blood
        if inspector.isVampire {
            return inspector.bloodMeter.bloodPercentage >= 10.0
        }
        
        return true
    }
    
    func investigate(inspector: any Character, investigationObject: any Character) {
        guard canInvestigate(inspector: inspector, investigationObject: investigationObject) else {
            return
        }
        
        // Adjust game time
        gameTime.advanceTime(hours: 1)
        
        // Investigate the object
        investigationObject.isUnknown = false
        
        // Update statistics
        statisticsService.incrementInvestigations()
        
        gameEventsBus.addSystemMessage("\(investigationObject.name). " +
                                        "It's \(investigationObject.sex) " +
                                       "\(investigationObject.profession).")
    }
} 
