import SwiftUI

@main
struct CRProjectApp: App {
    init() {
        // Register services in the correct order
        let dependencyManager = DependencyManager.shared
        
        // Register core services first
        dependencyManager.register(LocationReader())
        dependencyManager.register(NPCReader())
        dependencyManager.register(StatisticsService())
        dependencyManager.register(GameTimeService())
        dependencyManager.register(GameEventsBusService())
        
        // Then register other services
        dependencyManager.register(VampireNatureRevealService())
        dependencyManager.register(BloodManagementService())
        dependencyManager.register(FeedingService())
        dependencyManager.register(InvestigationService())
        dependencyManager.register(GameStateService(
            gameTime: dependencyManager.resolve(),
            vampireNatureRevealService: dependencyManager.resolve()
        ))
        dependencyManager.register(LocationEventsService(
            gameEventsBus:dependencyManager.resolve(),
            vampireNatureRevealService: dependencyManager.resolve(),
            gameStateService: dependencyManager.resolve()
        ))
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            MainSceneView(viewModel: MainSceneViewModel())
        }
    }
}
