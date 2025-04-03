import SwiftUI
import CoreHaptics
import QuartzCore

// MARK: - Rotation Animator
class RotationAnimator: NSObject {
    var onUpdate: ((Double) -> Void)?
    private var displayLink: CADisplayLink?
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        let targetFPS: Double = 120
        let frameDuration = 1.0 / targetFPS
        onUpdate?(frameDuration)
    }
}

// MARK: - Circular NPC View
struct CircularNPCView: View {
    let npcs: [NPC]
    var onAction: (NPCAction) -> Void
    
    @State private var rotationAngle: Double = 0
    @State private var selectedNPC: NPC? = nil
    @State private var animatedNPC: NPC? = nil
    @State private var rotationAnimator = RotationAnimator()
    @State private var hapticEngine: CHHapticEngine?
    @State private var isWheelSpinning = true
    
    // Layout constants
    private let radius: CGFloat = 115
    private let npcButtonSize: CGFloat = 70
    private let sigilSize: CGFloat = 130
    private let autoRotationSpeed: Double = 0.08
    
    // Immediate interaction flags
    @State private var isMenuVisible = false
    @State private var isMenuDismissing = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
            
            ZStack {
                // Fixed center sigil
                sigilView(center: center)
                
                // NPC wheel container
                npcWheelView(geometry: geometry, center: center)
                
                // Context Menu View
                contextMenuView()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                prepareHaptics()
                rotationAnimator.onUpdate = { frameDuration in
                    DispatchQueue.main.async {
                        if isWheelSpinning && !isMenuVisible {
                            withAnimation(.linear(duration: 1.0)) {
                                rotationAngle += autoRotationSpeed * frameDuration * 60
                                if rotationAngle >= 360 { rotationAngle = 0 }
                            }
                        }
                    }
                }
                rotationAnimator.start()
            }
            .onDisappear {
                rotationAnimator.stop()
            }
        }
        .frame(height: 270)
        .contentShape(Rectangle())
        .onTapGesture {
            if isMenuVisible {
                dismissMenu()
            }
        }
    }
    
    // MARK: - Subviews
    
    private func sigilView(center: CGPoint) -> some View {
        Image("vampireSigil")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: sigilSize, height: sigilSize)
            .shadow(color: .black, radius: 3, x: 0, y: 2)
            .position(center)
            .zIndex(0)
    }
    
    private func npcWheelView(geometry: GeometryProxy, center: CGPoint) -> some View {
        ZStack {
            ForEach(npcs, id: \.id) { npc in
                npcButton(npc: npc, center: center)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .rotationEffect(.degrees(rotationAngle))
        .disabled(isMenuVisible || isMenuDismissing)
        .zIndex(1)
    }
    
    private func npcButton(npc: NPC, center: CGPoint) -> some View {
        let index = npcs.firstIndex(where: { $0.id == npc.id })!
        let angle = angleForNPC(index: index, total: npcs.count)
        let position = positionOnCircle(angle: angle, radius: radius)
        
        return NPCButton(npc: npc, size: npcButtonSize, rotation: -rotationAngle)
            .position(x: position.x + center.x, y: position.y + center.y)
            .scaleEffect(animatedNPC?.id == npc.id ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: animatedNPC?.id == npc.id)
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        guard !isMenuVisible && !isMenuDismissing else { return }
                        
                        triggerHaptic()
                        withAnimation {
                            animatedNPC = npc
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isMenuVisible = true
                            withAnimation(.spring()) {
                                selectedNPC = npc
                                animatedNPC = nil
                                isWheelSpinning = false
                            }
                        }
                    }
            )
            .zIndex(selectedNPC?.id == npc.id ? 3 : 1)
    }
    
    private func contextMenuView() -> some View {
        Group {
            if isMenuVisible || isMenuDismissing {
                // Background dismiss layer
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissMenu()
                    }
                    .zIndex(2)
                
                // Menu content - only show if not dismissing
                if isMenuVisible, let npc = selectedNPC {
                    VStack(spacing: 8) {
                        NPCButtonPreview(npc: npc, onAction: { action in
                            handleAction(action: action, npc: npc)
                        })
                        .transition(.scale.combined(with: .opacity))
                        
                        actionButtons(for: npc)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(4)
                }
            }
        }
    }
    
    private func dismissMenu() {
        guard isMenuVisible else { return }
        
        isMenuDismissing = true
        isMenuVisible = false
        
        withAnimation(.spring()) {
            selectedNPC = nil
            isWheelSpinning = true
        }
        
        // Reset state after animation would complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isMenuDismissing = false
        }
    }
    
    private func actionButtons(for npc: NPC) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Status: ")
                    .font(Theme.captionFont)
                Text(npc.isAlive ? "Alive" : "Dead")
                    .font(.caption)
                    .foregroundColor(npc.isAlive ? .green : .red)
            }
            if !npc.isUnknown {
                if npc.isVampire {
                    Text("Vampire")
                        .font(Theme.captionFont)
                        .foregroundColor(Color.red)
                } else {
                    Text("Mortal")
                        .font(Theme.captionFont)
                        .foregroundColor(Color.blue)
                }
                Spacer()
            }
            
            if npc.isUnknown {
                HStack {
                    Text("Sex: \(npc.sex)")
                        .font(.caption)
                    Text("Age: \(npc.age)")
                        .font(.caption)
                }
            } else {
                VStack(spacing: 2) {
                    Text(npc.name)
                        .font(.headline)
                    Text("Sex: \(npc.sex)")
                        .font(.caption)
                    Text("Profession: \(npc.profession)")
                        .font(.caption)
                    Text("Age: \(npc.age)")
                        .font(.caption)
                }
            }
            
            if npc.isUnknown {
                ContextMenuButton(
                    action: {
                        handleAction(action: .investigate(npc), npc: npc)
                        triggerCustomHaptic(intensity: 0.5, sharpness: 0.5, duration: 0.5)
                    },
                    label: "Investigate",
                    icon: "arrow.triangle.2.circlepath",
                    color: Color.blue
                )
            }
            
            if npc.isAlive {
                aliveNPCButtons(for: npc)
            }
        }
        .padding(8)
        .background(Theme.secondaryColor.opacity(0.9))
        .cornerRadius(8)
        .frame(width: 280)
        .shadow(radius: 5)
    }
    
    private func aliveNPCButtons(for npc: NPC) -> some View {
        Group {
            ContextMenuButton(
                action: {
                    handleAction(action: .startConversation(npc), npc: npc)
                    triggerCustomHaptic(intensity: 0.3, sharpness: 0.3, duration: 0.5)
                },
                label: "Start conversation",
                icon: "bubble.left",
                color: .blue
            )
            
            if !npc.isUnknown && !npc.isVampire {
                ContextMenuButton(
                    action: {
                        handleAction(action: .feed(npc), npc: npc)
                        triggerCustomHaptic(intensity: 0.7, sharpness: 0.5, duration: 0.5)
                    },
                    label: "Feed",
                    icon: "drop.fill",
                    color: Color.red
                )
            }
            
            if !npc.isVampire {
                ContextMenuButton(
                    action: {
                        handleAction(action: .drain(npc), npc: npc)
                        triggerCustomHaptic(intensity: 1.0, sharpness: 0.8, duration: 1.0)
                    },
                    label: "Drain",
                    icon: "bolt.fill",
                    color: Color.red
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleAction(action: NPCAction, npc: NPC) {
        onAction(action)
        if case .drain = action, !npc.isAlive {
            dismissMenu()
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }
    
    private func triggerHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        if hapticEngine == nil {
            prepareHaptics()
        }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic failed: \(error.localizedDescription)")
            prepareHaptics()
        }
    }
    
    private func triggerCustomHaptic(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        if hapticEngine == nil {
            prepareHaptics()
        }
        
        do {
            let pattern: CHHapticPattern
            
            if duration > 0.3 {
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: 0,
                    duration: duration
                )
                pattern = try CHHapticPattern(events: [event], parameters: [])
            } else {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: 0
                )
                pattern = try CHHapticPattern(events: [event], parameters: [])
            }
            
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic failed: \(error.localizedDescription)")
            prepareHaptics()
        }
    }
    
    private func angleForNPC(index: Int, total: Int) -> Angle {
        Angle(degrees: (360 / Double(total)) * Double(index) - 90)
    }
    
    private func positionOnCircle(angle: Angle, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: radius * cos(CGFloat(angle.radians)),
            y: radius * sin(CGFloat(angle.radians))
        )
    }
}

// MARK: - NPC Button
struct NPCButton: View {
    let npc: NPC
    let size: CGFloat
    let rotation: Double
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                // Metallic frame (placed first so it appears underneath)
                Image("iconFrame")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 1.02, height: size * 1.02)
                    .rotationEffect(.degrees(rotation))
                    .clipShape(Circle())
                
                // Background circle
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: size * 0.85, height: size * 0.85) // Smaller to fit inside frame
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // NPC icon (smaller to fit inside the frame)
                Image(getImageName(npc: npc))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.8, height: size * 0.8) // Smaller than background
                    .rotationEffect(.degrees(rotation))
                    .clipShape(Circle())
            }
        }
        .shadow(color: .black, radius: 1, x: 0, y: 2)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
    }
    
    private func getImageName(npc: NPC) -> String {
        if npc.isAlive {
            if npc.isUnknown {
                return npc.sex == .male ? "maleIcon" : "femaleIconAlt"
            } else {
                if npc.isVampire {
                    return npc.sex == .male ? "vampireMaleIcon" : "vampireFemaleIcon"
                } else {
                    return npc.sex == .male ? "maleIcon" : "femaleIconAlt"
                }
            }
        } else {
            return "graveIcon"
        }
    }
}

// MARK: - NPC Button Preview
struct NPCButtonPreview: View {
    let npc: NPC
    let onAction: (NPCAction) -> Void
    
    var body: some View {
        Button(action: {}) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: 60, height: 60)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .contextMenu {
            // Single context menu with all actions
            VStack(spacing: 4) {
                ContextMenuButton(
                    action: { onAction(.investigate(npc)) },
                    label: "Investigate",
                    icon: "arrow.triangle.2.circlepath",
                    color: Color.blue
                )
                
                ContextMenuButton(
                    action: { onAction(.startConversation(npc)) },
                    label: "Start conversation",
                    icon: "bubble.left",
                    color: .blue
                )
                
                ContextMenuButton(
                    action: { onAction(.feed(npc)) },
                    label: "Feed",
                    icon: "drop.fill",
                    color: Color.red
                )
                
                ContextMenuButton(
                    action: { onAction(.drain(npc)) },
                    label: "Drain",
                    icon: "bolt.fill",
                    color: Color.red
                )
            }
            .padding(8)
        }
    }
}

// MARK: - Context Menu Button
struct ContextMenuButton: View {
    let action: () -> Void
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .font(Theme.captionFont)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(6)
    }
}
