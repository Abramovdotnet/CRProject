import SwiftUI
import UIKit

struct TradeViewControllerWrapper: UIViewControllerRepresentable {
    let player: Player
    let npc: NPC
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> TradeViewController {
        let controller = TradeViewController(
            player: player,
            npc: npc,
            scene: scene,
            mainViewModel: mainViewModel,
            onDismiss: {
                dismiss()
            }
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: TradeViewController, context: Context) {
        // Update if needed
    }
} 