import Foundation

class InvestigationService: GameService {
    private let bloodService: BloodManagementService
    private let gameTime: GameTimeService
    private let statisticsService: StatisticsService
    private let gameEventsBus: GameEventsBusService
    static let shared: InvestigationService = DependencyManager.shared.resolve()
    
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
        
        return true
    }
    
    func investigate(inspector: any Character, investigationObject: any Character) {
        guard canInvestigate(inspector: inspector, investigationObject: investigationObject) else {
            return
        }
        
        // Investigate the object
        investigationObject.isUnknown = false
        investigationObject.isBeasyByPlayerAction = true
        
        // Update statistics
        statisticsService.incrementInvestigations()
    }
} 
