import SwiftUI

@main
struct CRProjectApp: App {
    init() {
        // Register services in the correct order
        let dependencyManager = DependencyManager.shared
        
        // Register StatisticsService first
        dependencyManager.register(StatisticsService())
        
        // Then register other services
        dependencyManager.register(VampireNatureRevealService())
        dependencyManager.register(GameTimeService())
        dependencyManager.register(BloodManagementService())
        dependencyManager.register(FeedingService())
        dependencyManager.register(InvestigationService())
        dependencyManager.register(GameStateService(
            gameTime: dependencyManager.resolve(),
            vampireNatureRevealService: dependencyManager.resolve()
        ))
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            DebugView()
        }
    }
}
