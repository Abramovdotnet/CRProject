import SwiftUI
import UIKit

struct PopUpBannerWrapper: UIViewControllerRepresentable {
    let title: String
    let description: String
    let icon: UIImage?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        DispatchQueue.main.async {
            UIKitPopUpManager.shared.show(title: title, description: description, icon: icon)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
} 
