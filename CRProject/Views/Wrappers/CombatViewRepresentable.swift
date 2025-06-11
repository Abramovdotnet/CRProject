import SwiftUI

struct CombatViewRepresentable: UIViewControllerRepresentable {
    let mainViewModel: MainSceneViewModel
    let npc: NPC
    var onLeave: (() -> Void)? = nil
    var onLoot: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> CombatViewController {
        let vc = CombatViewController(mainViewModel: mainViewModel, npc: npc)
        vc.onLeave = onLeave
        vc.onLoot = onLoot
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CombatViewController, context: Context) {
        // Обновление состояния при необходимости
    }
} 