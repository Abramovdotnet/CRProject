import SwiftUI
import UIKit

struct WorldMapViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var gameStateService = GameStateService.shared // Отслеживаем изменения
    var mainViewModel: MainSceneViewModel
    typealias UIViewControllerType = WorldMapViewController

    func makeUIViewController(context: Context) -> WorldMapViewController {
        let vc = WorldMapViewController(mainViewModel: mainViewModel)
        // Передаем начальное состояние, если нужно, хотя viewDidLoad в VC и так его получит
        // vc.centerMapOn(sceneId: gameStateService.currentScene?.id) // Можно, но viewDidLoad сделает то же самое
        return vc
    }

    func updateUIViewController(_ uiViewController: WorldMapViewController, context: Context) {
        // Вызываем перецентрирование при обновлении currentScene
        print("[WorldMapViewRepresentable] updateUIViewController called. Current scene ID: \(gameStateService.currentScene?.id ?? -1)")
        uiViewController.centerMapOn(sceneId: gameStateService.currentScene?.id, animated: true)
    }
} 