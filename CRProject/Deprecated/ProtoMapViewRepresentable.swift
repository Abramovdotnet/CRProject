import SwiftUI
import UIKit

struct ProtoMapViewRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = ProtoMapViewController
    
    var calculatedScenes: [CalculatedScene]
    var onDismiss: () -> Void // Добавим колбэк для закрытия, если понадобится
    
    func makeUIViewController(context: Context) -> ProtoMapViewController {
        let vc = ProtoMapViewController(calculatedScenes: calculatedScenes)
        // Если бы у ProtoMapViewController был делегат или колбэк для закрытия, настроили бы здесь
        // Например, vc.onDismissRequested = { self.onDismiss() }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ProtoMapViewController, context: Context) {
        // В данном простом случае, если calculatedScenes изменятся,
        // мы могли бы пересоздать viewController или добавить метод для обновления данных.
        // Для прототипа пока оставим так.
        // Если бы ProtoMapViewController имел метод для обновления данных:
        // uiViewController.update(with: calculatedScenes)
    }
    
    // Можно добавить Coordinator, если потребуется обрабатывать делегаты от ProtoMapViewController
    // func makeCoordinator() -> Coordinator {
    //     Coordinator(self)
    // }
    //
    // class Coordinator: NSObject {
    //     var parent: ProtoMapViewRepresentable
    //     init(_ parent: ProtoMapViewRepresentable) {
    //         self.parent = parent
    //     }
    //     // Пример метода, который мог бы вызываться из UIKit
    //     @objc func dismissProtoMap() {
    //         parent.onDismiss()
    //     }
    // }
} 