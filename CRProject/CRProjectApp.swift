import SwiftUI

@main
struct CRProjectApp: App {
    init() {
        // Register services
        DependencyManager.shared.register(BloodManagementService())
        DependencyManager.shared.register(FeedingService())
        DependencyManager.shared.register(GameTime())
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            DebugView()
        }
    }
}
