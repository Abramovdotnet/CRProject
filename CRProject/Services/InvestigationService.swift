import Foundation

class InvestigationService: GameService {
    private let bloodService: BloodManagementService
    private let gameTime: GameTimeService
    private let statisticsService: StatisticsService
    
    init(bloodService: BloodManagementService = DependencyManager.shared.resolve(),
         gameTime: GameTimeService = DependencyManager.shared.resolve(),
         statisticsService: StatisticsService = DependencyManager.shared.resolve()) {
        self.bloodService = bloodService
        self.gameTime = gameTime
        self.statisticsService = statisticsService
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
        
        // Share blood if inspector is vampire
        if inspector.isVampire {
            inspector.shareBlood(amount: 10.0, from: inspector)
        }
        
        // Investigate the object
        investigationObject.isUnknown = false
        
        // Update statistics
        statisticsService.incrementInvestigations()
    }
} 
