import CoreHaptics
import UIKit // Needed for UIApplication background notifications

final class VibrationService {
    static let shared = VibrationService()
    private var engine: CHHapticEngine?
    private var engineNeedsStart = true
    
    // Flags to prevent repeated logging
    private static var hardwareSupportChecked = false
    private static var hardwareSupportsHaptics = false
    private var engineInitializationAttempted = false
    private var engineInitializationFailed = false

    private init() {
        // Check hardware support only once
        if !VibrationService.hardwareSupportChecked {
            VibrationService.hardwareSupportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
            if !VibrationService.hardwareSupportsHaptics {
                print("Haptics not supported on this device.")
            }
            VibrationService.hardwareSupportChecked = true
        }
        
        guard VibrationService.hardwareSupportsHaptics else { return }
        
        createAndStartHapticEngine()
        
        // Add observers for app lifecycle events
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillResignActive),
                                               name: UIApplication.willResignActiveNotification, 
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func createAndStartHapticEngine() {
        guard VibrationService.hardwareSupportsHaptics else { return }
        guard engine == nil else {
             if engineNeedsStart {
                 startHapticEngine()
             }
             return
        }
        
        engineInitializationAttempted = true // Mark that we tried
        engineInitializationFailed = false // Reset failure flag on creation attempt

        print("Creating Haptic Engine")
        do {
            engine = try CHHapticEngine()
        } catch let error {
            print("Haptic Engine Creation Error: \(error)")
            engineInitializationFailed = true // Set failure flag
            return
        }

        // Set up handlers before starting
        engine?.stoppedHandler = { [weak self] reason in
            print("Haptic Engine Stopped: \(reason)")
            self?.engineNeedsStart = true
        }

        engine?.resetHandler = { [weak self] in
            print("Haptic Engine Reset")
            self?.engineNeedsStart = true
            // Try to restart the engine automatically after a reset
            self?.startHapticEngine()
        }
        
        // Start the engine
        startHapticEngine()
    }
    
    private func startHapticEngine() {
        guard let engine = engine, engineNeedsStart else { return }
        
        // print("Attempting to start Haptic Engine...") // Reduce noise
        do {
            try engine.start()
            engineNeedsStart = false
            print("Haptic Engine Started Successfully.")
        } catch let error {
            if !engineInitializationFailed { // Log only the first time initialization fails
                 print("Haptic Engine Start Error: \(error)")
                 engineInitializationFailed = true // Set failure flag
            }
            // Keep engineNeedsStart = true
        }
    }
    
    private func stopHapticEngine() {
        guard let engine = engine, !engineNeedsStart else { return }
        print("Stopping Haptic Engine.")
        engine.stop()
        engineNeedsStart = true
    }
    
    // --- App Lifecycle Handlers ---
    @objc private func handleAppWillResignActive() {
        print("App resigning active, stopping haptics.")
        stopHapticEngine()
    }
    
    @objc private func handleAppDidBecomeActive() {
        print("App became active, ensuring haptics are ready.")
        // Ensure engine exists and try starting if needed
        if engine == nil {
           createAndStartHapticEngine()
        } else if engineNeedsStart {
           startHapticEngine()
        }
    }
    
    // --- Public Vibration Method ---
    func vibrate(
        intensity: Float = 0.5,
        sharpness: Float = 0.5,
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0
    ) {
        // Use the static hardware support check
        guard VibrationService.hardwareSupportsHaptics else {
            // No need to log again, was logged in init
            return
        }
        
        // Simplified check: If engine is nil, log once if necessary and return.
        guard let currentEngine = self.engine else {
            if engineInitializationAttempted && !engineInitializationFailed {
                // Log only once per failure period
                print("Haptic engine is nil or failed initialization. Cannot vibrate.")
                engineInitializationFailed = true // Set flag to prevent repeated logs
            } else if !engineInitializationAttempted {
                 // This case might indicate an issue if called frequently
                 print("Haptic engine initialization not yet attempted when vibrate called.")
            }
            return // Exit scope
        }

        // Ensure engine is started before playing (use currentEngine)
        if engineNeedsStart {
            startHapticEngine()
            if engineNeedsStart { 
                // Do not log repeatedly if start keeps failing
                return // Exit scope
            }
        }
        
        // Use currentEngine from now on
        var events = [CHHapticEvent]()
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: delay,
            duration: duration
        )
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try currentEngine.makePlayer(with: pattern) // Use currentEngine
            try player.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
            if let hapticError = error as? CHHapticError, hapticError.code == .engineNotRunning {
                print("Engine was not running: \(hapticError.code). Flagging for restart.")
                engineNeedsStart = true
            } else {
                 print("Caught other error when playing pattern: \(error)")
            }
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
    
    func regularTap() {
        vibrate(intensity: 0.1, sharpness: 0.6, duration: 0.1)
    }
    
    // Ensure observers are removed
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
