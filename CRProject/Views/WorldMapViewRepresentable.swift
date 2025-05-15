import SwiftUI
import UIKit

struct WorldMapViewRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = WorldMapViewController

    func makeUIViewController(context: Context) -> WorldMapViewController {
        let vc = WorldMapViewController()
        // Тут можно передать какие-то начальные данные или делегаты, если нужно
        return vc
    }

    func updateUIViewController(_ uiViewController: WorldMapViewController, context: Context) {
        // Обновление контроллера, если данные из SwiftUI изменились
    }
} 