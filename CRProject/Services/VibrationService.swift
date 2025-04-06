import CoreHaptics

final class VibrationService {
    static let shared = VibrationService()
    private var engine: CHHapticEngine?
    
    private init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }
    
    func vibrate(
        intensity: Float = 0.5,
        sharpness: Float = 0.5,
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0
    ) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        // Create continuous vibration for duration
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: delay,
            duration: duration
        )
        events.append(event)
        
        // Convert events to pattern and play
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription)")
        }
    }
    
    // Convenience presets
    func successVibration() {
        vibrate(intensity: 0.7, sharpness: 0.3, duration: 0.3)
    }
    
    func errorVibration() {
        vibrate(intensity: 1.0, sharpness: 0.8, duration: 0.6)
    }
    
    func lightTap() {
        vibrate(intensity: 0.3, sharpness: 0.3, duration: 0.1)
    }
}
