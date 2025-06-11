import SwiftUI
import UIKit
import Combine

struct DialogueViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: DialogueViewModel
    let mainViewModel: MainSceneViewModel
    let isSkipable: Bool
    let onDismiss: () -> Void
    
    init(viewModel: DialogueViewModel, mainViewModel: MainSceneViewModel, isSkipable: Bool = true, onDismiss: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.mainViewModel = mainViewModel
        self.isSkipable = isSkipable
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> DialogueViewController {
        let controller = DialogueViewController(
            viewModel: viewModel,
            mainViewModel: mainViewModel,
            isSkipable: isSkipable
        )
        
        // Subscribe to shouldDismiss changes and handle dismiss through SwiftUI
        viewModel.$shouldDismiss
            .receive(on: DispatchQueue.main)
            .sink { shouldDismiss in
                DebugLogService.shared.log("🚪 DialogueViewControllerWrapper: shouldDismiss changed to: \(shouldDismiss)", category: "Wrapper")
                if shouldDismiss {
                    DebugLogService.shared.log("🚪 DialogueViewControllerWrapper: Calling onDismiss closure", category: "Wrapper")
                    onDismiss()
                }
            }
            .store(in: &context.coordinator.cancellables)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DialogueViewController, context: Context) {
        // Update the controller if needed when SwiftUI state changes
        // The DialogueViewController listens to its viewModel changes through Combine
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var cancellables = Set<AnyCancellable>()
    }
}

#if DEBUG
struct DialogueViewControllerWrapper_Previews: PreviewProvider {
    static var previews: some View {
        Text("DialogueViewController Preview")
            .foregroundColor(.white)
            .background(Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif 