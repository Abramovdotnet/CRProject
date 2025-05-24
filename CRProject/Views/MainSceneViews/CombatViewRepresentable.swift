import SwiftUI

struct CombatViewRepresentable: UIViewControllerRepresentable {
    let mainViewModel: MainSceneViewModel
    let npc: NPC
    
    func makeUIViewController(context: Context) -> CombatViewController {
        return CombatViewController(mainViewModel: mainViewModel, npc: npc)
    }
    
    func updateUIViewController(_ uiViewController: CombatViewController, context: Context) {
        // Обновление состояния при необходимости
    }
} 