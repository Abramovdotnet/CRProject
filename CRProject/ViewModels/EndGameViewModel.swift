import Foundation
import Combine

class EndGameViewModel: ObservableObject {
    @Published var showEndGame: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default
            .publisher(for: .exposed)
            .sink { [weak self] _ in
                self?.endGame()
            }
            .store(in: &cancellables)
    }
    
    private func endGame() {
        showEndGame = true
    }
}
