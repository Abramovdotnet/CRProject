import SwiftUI

@main
struct CRProjectApp: App {
    init() {
        // Register services
        DependencyManager.shared.register(GameTime())
        DependencyManager.shared.register(VampireNatureRevealService())
        DependencyManager.shared.register(BloodManagementService())
        DependencyManager.shared.register(FeedingService())
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            DebugView()
        }
    }
}
