import SwiftUI
import UIKit

struct CharacterInventoryViewControllerWrapper: UIViewControllerRepresentable {
    let character: any Character
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    let onDismiss: () -> Void
    
    init(character: any Character, scene: Scene, mainViewModel: MainSceneViewModel, onDismiss: @escaping () -> Void = {}) {
        self.character = character
        self.scene = scene
        self.mainViewModel = mainViewModel
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> CharacterInventoryViewController {
        // Always get the latest player data from GameStateService
        let currentCharacter: any Character
        if character is Player {
            currentCharacter = GameStateService.shared.player ?? character
        } else {
            currentCharacter = character
        }
        
        let controller = CharacterInventoryViewController(
            character: currentCharacter,
            scene: scene,
            mainViewModel: mainViewModel
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CharacterInventoryViewController, context: Context) {
        // Force update the content when the view updates
        uiViewController.refreshCharacterData()
        uiViewController.updateInventoryContent()
    }
} 