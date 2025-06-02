import SwiftUI
import UIKit

struct SmithingViewControllerWrapper: UIViewControllerRepresentable {
    let player: Player
    let mainViewModel: MainSceneViewModel
    let onDismiss: () -> Void
    
    init(player: Player, mainViewModel: MainSceneViewModel, onDismiss: @escaping () -> Void = {}) {
        self.player = player
        self.mainViewModel = mainViewModel
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> SmithingViewController {
        let controller = SmithingViewController(
            player: player,
            mainViewModel: mainViewModel
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SmithingViewController, context: Context) {
        // The SmithingViewController automatically updates through Combine observers
        // No manual refresh needed as it observes SmithingViewModel and related services
    }
} 