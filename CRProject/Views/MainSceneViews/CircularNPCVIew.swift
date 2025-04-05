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
    @State private var lightningPhase: CGFloat = 0
    
    // Menu visibility states
    @State private var isMenuVisible = false
    @State private var isMenuDismissing = false
    
    // Inner circle rotations
    @State private var rotationAngle2: Double = 0 // Middle circle (counter-clockwise)
    @State private var rotationAngle3: Double = 0 // Inner circle (clockwise)
    
    // Layout constants with increased spacing
    private let outerRadius: CGFloat = 135
    private let middleRadius: CGFloat = 90
    private let innerRadius: CGFloat = 55
    private let npcButtonSize: CGFloat = 45
    private let sigilSize: CGFloat = 130
    private let autoRotationSpeed: Double = 0.18
    private let circleSpacing: CGFloat = 45
    
    // Lightning colors
    private let darkCrimson = Color(red: 0.6, green: 0.0, blue: 0.1)
    private let crimsonGlow = Color(red: 0.8, green: 0.2, blue: 0.3)
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
            
            ZStack {
                // Fixed center sigil
                sigilView(center: center)
                
                // Draw lightning connections first (behind buttons)
                lightningConnections(center: center, geometry: geometry)
                
                // Outer circle (spins clockwise) - Highest zIndex since it's on top
                npcWheelView(geometry: geometry, center: center,
                            radius: outerRadius, rotation: rotationAngle,
                            clockwise: true, npcs: Array(npcs.prefix(min(10, npcs.count))),
                            buttonSize: npcButtonSize)
                    .zIndex(3)
                
                // Middle circle (spins counter-clockwise)
                if npcs.count > 10 {
                    npcWheelView(geometry: geometry, center: center,
                                radius: middleRadius, rotation: rotationAngle2,
                                clockwise: false, npcs: Array(npcs[10..<min(20, npcs.count)]),
                                buttonSize: npcButtonSize * 0.75)
                        .zIndex(2)
                }
                
                // Inner circle (spins clockwise)
                if npcs.count > 20 {
                    npcWheelView(geometry: geometry, center: center,
                                radius: innerRadius, rotation: rotationAngle3,
                                clockwise: true, npcs: Array(npcs.suffix(from: 20)),
                                buttonSize: npcButtonSize * 0.6)
                        .zIndex(1)
                }
                
                // Context Menu View
                contextMenuView()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                prepareHaptics()
                rotationAnimator.onUpdate = { frameDuration in
                    DispatchQueue.main.async {
                        if isWheelSpinning && !isMenuVisible {
                            // Remove the animation wrapper - let the display link handle smooth updates
                            rotationAngle += autoRotationSpeed * frameDuration * 60        // Outer clockwise
                            rotationAngle2 -= autoRotationSpeed * 0.7 * frameDuration * 60 // Middle counter-clockwise
                            rotationAngle3 += autoRotationSpeed * 0.5 * frameDuration * 60 // Inner clockwise
                            
                            // Normalize angles
                            rotationAngle = rotationAngle.truncatingRemainder(dividingBy: 360)
                            rotationAngle2 = rotationAngle2.truncatingRemainder(dividingBy: 360)
                            rotationAngle3 = rotationAngle3.truncatingRemainder(dividingBy: 360)
                            
                            // Update lightning animation
                            lightningPhase += 0.05
                        }
                    }
                }
                rotationAnimator.start()
            }
            .onDisappear {
                rotationAnimator.stop()
            }
        }
        .frame(height: 300)
        .contentShape(Rectangle())
        .onTapGesture {
            if isMenuVisible {
                dismissMenu()
            }
        }
    }
    
    private func lightningConnections(center: CGPoint, geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Draw lightning to all known NPCs
            for npc in npcs where !npc.isUnknown {
                guard let buttonPosition = positionForNPC(npc: npc, center: center) else { continue }
                
                // Create a lightning path from center to NPC button
                let start = center
                let end = buttonPosition
                
                // Create multiple lightning bolts for a more dramatic effect
                for i in 0..<3 { // Three layers of lightning for thickness
                    let offset = CGFloat(i) * 3 - 3 // Creates variation in paths
                    let jitter: CGFloat = 8 // Increased jitter for more organic look
                    
                    var path = Path()
                    path.move(to: start)
                    
                    let segments = 12 // More segments for smoother lightning
                    for i in 1..<segments {
                        let progress = CGFloat(i) / CGFloat(segments)
                        let baseX = start.x + (end.x - start.x) * progress
                        let baseY = start.y + (end.y - start.y) * progress
                        
                        // Add jitter that decreases toward the end
                        let offsetX = (CGFloat.random(in: -jitter...jitter) + offset) * (1 - progress)
                        let offsetY = (CGFloat.random(in: -jitter...jitter) + offset) * (1 - progress)
                        
                        path.addLine(to: CGPoint(
                            x: baseX + offsetX * sin(lightningPhase * 2 + CGFloat(i) * 0.5),
                            y: baseY + offsetY * cos(lightningPhase * 1.5 + CGFloat(i) * 0.3)
                        ))
                    }
                    
                    path.addLine(to: end)
                    
                    // Main lightning stroke with dark crimson gradient
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [darkCrimson, crimsonGlow]),
                            startPoint: start,
                            endPoint: end
                        ),
                        lineWidth: i == 0 ? 0.2 : 0.1 // Thicker main line
                    )
                    
                    // Add intense glow
                    context.blendMode = .plusLighter
                    context.stroke(
                        path,
                        with: .color(crimsonGlow.opacity(0.4)),
                        lineWidth: 0.5 // Wider glow
                    )
                    
                    // Add subtle outer glow
                    context.blendMode = .screen
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.1)),
                        lineWidth: 0.7
                    )
                }
            }
        }
    }
    
    private func positionForNPC(npc: NPC, center: CGPoint) -> CGPoint? {
        let allNPCs = npcs
        guard let index = allNPCs.firstIndex(where: { $0.id == npc.id }) else { return nil }
        
        let circleIndex: Int
        let radius: CGFloat
        let rotation: Double
        
        if index < 10 {
            circleIndex = index
            radius = outerRadius
            rotation = rotationAngle
        } else if index < 20 {
            circleIndex = index - 10
            radius = middleRadius
            rotation = rotationAngle2
        } else {
            circleIndex = index - 20
            radius = innerRadius
            rotation = rotationAngle3
        }
        
        let circleCount = index < 10 ? min(10, allNPCs.count) :
                          index < 20 ? min(10, max(0, allNPCs.count - 10)) :
                          max(0, allNPCs.count - 20)
        
        let angle = Angle(degrees: (360 / Double(circleCount)) * Double(circleIndex) - 90 + rotation)
        let position = positionOnCircle(angle: angle, radius: radius)
        return CGPoint(x: position.x + center.x, y: position.y + center.y)
    }
    
    private func npcWheelView(geometry: GeometryProxy, center: CGPoint,
                            radius: CGFloat, rotation: Double, clockwise: Bool,
                            npcs: [NPC], buttonSize: CGFloat) -> some View {
        ZStack {
            ForEach(npcs.indices, id: \.self) { index in
                let npc = npcs[index]
                let angle = Angle(degrees: (360 / Double(npcs.count)) * Double(index) - 90)
                let position = positionOnCircle(angle: angle, radius: radius)
                
                NPCButton(npc: npc, size: buttonSize, rotation: clockwise ? -rotation : rotation)
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
        }
        .rotationEffect(.degrees(rotation), anchor: .center)
        .disabled(isMenuVisible || isMenuDismissing)
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
            if !npc.isUnknown {
                if npc.isVampire {
                    Text("Vampire")
                        .font(Theme.subheadingFont)
                        .foregroundColor(Color.red)
                } else {
                    Text("Mortal")
                        .font(Theme.subheadingFont)
                        .foregroundColor(Color.blue)
                }
                Spacer()
            }
            
            HStack {
                Text("Status: ")
                    .font(Theme.captionFont)
                Text(npc.isAlive ? "Alive" : "Dead")
                    .font(.caption)
                    .foregroundColor(npc.isAlive ? .green : .red)
                
                if npc.isSleeping {
                    Image(systemName: "moon.fill")
                        .font(.caption)
                    Text(" Sleeping")
                        .font(Theme.captionFont)
                }
                
                if !npc.isUnknown {
                    Text("Blood: \(Int(npc.bloodMeter.currentBlood))%")
                        .font(Theme.bodyFont)
                }
            }
            
            if !npc.isUnknown {
                VStack {
                    ProgressBar(value: Double(npc.bloodMeter.currentBlood / 100.0), color: Theme.bloodProgressColor)
                }
                Spacer()
            }
            
            if npc.isUnknown {
                HStack {
                    Text("Sex: \(npc.sex)")
                        .font(.caption)
                }
            } else {
                VStack(spacing: 2) {
                    Text(npc.name)
                        .font(.headline)
                    HStack {
                        Text("Sex: \(npc.sex)")
                            .font(.caption)
                        Text("Profession: \(npc.profession)")
                            .font(.caption)
                        Text("Age: \(npc.age)")
                            .font(.caption)
                    }
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
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            DebugLogService.shared.log("Haptic engine error: \(error.localizedDescription)", category: "Error")
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
            DebugLogService.shared.log("Haptic failed: \(error.localizedDescription)", category: "Error")
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
            DebugLogService.shared.log("Haptic failed: \(error.localizedDescription)", category: "Error")
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

// MARK: - NPC Button (simplified without lightning or blue border)
struct NPCButton: View {
    let npc: NPC
    let size: CGFloat
    let rotation: Double
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                Image(getImageName(npc: npc))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.82, height: size * 0.82)
                
                Image("iconFrame")
                    .resizable()
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(npc.isVampire ? Color.red : Color.clear, lineWidth: 2) // Only red border for vampires
                            .opacity(npc.isUnknown ? 0 : 1)
                    )
            }.rotationEffect(.degrees(rotation))
        }
        .shadow(color: .black, radius: 3, x: 0, y: 2)
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
            .padding(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LightningPath: Shape {
    var points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}
