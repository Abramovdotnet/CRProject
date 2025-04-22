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
        dependencyManager.register(CoinsManagementService())
        dependencyManager.register(NPCInteractionEventsService())
        
        // Then register other services
        dependencyManager.register(VampireNatureRevealService())
        dependencyManager.register(BloodManagementService())
        dependencyManager.register(FeedingService())
        dependencyManager.register(InvestigationService())
        dependencyManager.register(GameStateService(
            gameTime: dependencyManager.resolve(),
            vampireNatureRevealService: dependencyManager.resolve()
        ))
        
        VibrationService.shared.successVibration()
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            MainSceneView(viewModel: MainSceneViewModel())
        }
    }
}
