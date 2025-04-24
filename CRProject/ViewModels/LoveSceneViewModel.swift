import SwiftUI
import Combine

class LoveSceneViewModel: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var iconOpacity: Double = 1.0
    @Published var blurRadius: CGFloat = 0.0
    @Published var shadowRadius: CGFloat = 5.0
    
    private var isAnimating = false
    private var animationTimer: Timer? 

    func startAnimation() {
        guard !isAnimating else { return } 
        isAnimating = true
        resetAnimationProperties() // Reset before starting

        // Start pulsating animation
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            self.scale = 1.3
            self.iconOpacity = 0.7 
            self.blurRadius = 3.0
            self.shadowRadius = 15.0
        }

        // Start vibration pattern
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self, self.isAnimating else {
                self?.stopTimer()
                return 
            }
            VibrationService.shared.vibrate(intensity: 0.7, sharpness: 0.5, duration: 0.1)
        }
    }

    func stopAnimation() {
        guard isAnimating else { return }
        isAnimating = false
        stopTimer()

        // Reset properties immediately when stopping the *pulsing* animation
        resetAnimationProperties()
        
        // Explicitly remove the repeating animation block
        withAnimation(nil) {
            self.scale = 1.0
            self.iconOpacity = 1.0
            self.blurRadius = 0.0
            self.shadowRadius = 5.0
        }
    }
    
    private func stopTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func resetAnimationProperties() {
        // Set properties directly without animation for reset
        scale = 1.0
        iconOpacity = 1.0
        blurRadius = 0.0
        shadowRadius = 5.0
    }
    
    // Ensure timer is stopped when the ViewModel is deinitialized
    deinit {
        stopTimer()
    }
} 