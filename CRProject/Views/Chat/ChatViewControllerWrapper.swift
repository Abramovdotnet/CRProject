import SwiftUI
import UIKit

struct ChatViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel = ChatViewModel()) {
        self.viewModel = viewModel
    }
    
    func makeUIViewController(context: Context) -> ChatViewController {
        return ChatViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: ChatViewController, context: Context) {
        // Updates can be handled through the view model if needed
    }
}

// MARK: - Convenience initializers for compatibility

extension ChatViewControllerWrapper {
    init(eventsBus: GameEventsBusService) {
        // For backward compatibility - create view model that uses the provided eventsBus
        self.init(viewModel: ChatViewModel())
    }
} 