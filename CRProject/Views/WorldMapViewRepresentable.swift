import SwiftUI
import UIKit

struct WorldMapViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var gameStateService = GameStateService.shared // Отслеживаем изменения
    var mainViewModel: MainSceneViewModel
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        // Используем новый прототипный контроллер
        return VirtualWorldMapViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Пока ничего не делаем
    }
} 
