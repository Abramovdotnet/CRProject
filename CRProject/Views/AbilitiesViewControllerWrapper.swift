import SwiftUI
import UIKit

struct AbilitiesViewControllerWrapper: UIViewControllerRepresentable {
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    let onDismiss: () -> Void
    
    init(scene: Scene, mainViewModel: MainSceneViewModel, onDismiss: @escaping () -> Void = {}) {
        self.scene = scene
        self.mainViewModel = mainViewModel
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> AbilitiesViewController {
        let controller = AbilitiesViewController(
            scene: scene,
            mainViewModel: mainViewModel
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AbilitiesViewController, context: Context) {
        // The AbilitiesViewController automatically updates through Combine observers
        // No manual refresh needed as it observes AbilitiesSystem and StatisticsService changes
    }
} 