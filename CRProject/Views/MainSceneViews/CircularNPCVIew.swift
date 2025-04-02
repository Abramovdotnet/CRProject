import SwiftUI
import CoreHaptics
import QuartzCore

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

struct CircularNPCView: View {
    let npcs: [NPC]
    @State private var rotationAngle: Double = 0
    @State private var selectedNPC: NPC? = nil
    @State private var animatedNPC: NPC? = nil
    @State private var rotationAnimator = RotationAnimator()
    @State private var hapticEngine: CHHapticEngine?
    
    // Layout constants
    private let radius: CGFloat = 108
    private let npcButtonSize: CGFloat = 40
    private let sigilSize: CGFloat = 130
    private let autoRotationSpeed: Double = 0.17
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
            
            ZStack {
                // Fixed center sigil
                Image("vampireSigil")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: sigilSize, height: sigilSize)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .position(center)
                
                // NPC wheel container
                ZStack {
                    ForEach(npcs, id: \.id) { npc in
                        let index = npcs.firstIndex(where: { $0.id == npc.id })!
                        let angle = angleForNPC(index: index, total: npcs.count)
                        let position = positionOnCircle(angle: angle, radius: radius)
                        
                        NPCButton(npc: npc, size: npcButtonSize, rotation: -rotationAngle)
                            .position(x: position.x + center.x, y: position.y + center.y)
                            .scaleEffect(animatedNPC?.id == npc.id ? 1.1 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: animatedNPC?.id == npc.id)
                            .highPriorityGesture(
                                TapGesture()
                                    .onEnded {
                                        triggerHaptic()
                                        withAnimation {
                                            animatedNPC = npc
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            withAnimation(.spring()) {
                                                selectedNPC = npc
                                                animatedNPC = nil
                                            }
                                        }
                                    }
                            )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .rotationEffect(.degrees(rotationAngle))
                .disabled(selectedNPC != nil)
                
                // Context Menu View
                if let npc = selectedNPC {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedNPC = nil
                            }
                        }
                    
                    VStack(spacing: 8) {
                        NPCButtonPreview(npc: npc)
                            .transition(.scale.combined(with: .opacity))
                        
                        VStack(spacing: 4) {
                            ContextMenuButton(
                                action: { selectedNPC = nil },
                                label: "Investigate",
                                icon: "arrow.triangle.2.circlepath",
                                color: Color.blue
                            )
                            ContextMenuButton(
                                action: { selectedNPC = nil },
                                label: "Start conversation",
                                icon: "bubble.left",
                                color: Color.blue
                            )
                            ContextMenuButton(
                                action: { selectedNPC = nil },
                                label: "Feed",
                                icon: "drop.fill",
                                color: Color.red
                            )
                            ContextMenuButton(
                                action: { selectedNPC = nil },
                                label: "Drain",
                                icon: "bolt.fill",
                                color: Color.red
                            )
                        }
                        .padding(8)
                        .background(Theme.secondaryColor.opacity(0.9))
                        .cornerRadius(8)
                        .frame(width: 280)
                        .shadow(radius: 5)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                prepareHaptics()
                rotationAnimator.onUpdate = { frameDuration in
                    DispatchQueue.main.async {
                        rotationAngle += autoRotationSpeed * frameDuration * 60
                        if rotationAngle >= 360 { rotationAngle = 0 }
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
            if selectedNPC != nil {
                withAnimation(.spring()) {
                    selectedNPC = nil
                }
            }
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
        
        // Restart engine if needed (in case npcs collection changed)
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
            // Attempt to restart engine if failed
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

struct NPCButton: View {
    let npc: NPC
    let size: CGFloat
    let rotation: Double
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                
                Image("flaconAltHealth")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .shadow(color: .black, radius: 1, x: 0, y: 2)
        .buttonStyle(PlainButtonStyle())
    }
}

struct NPCButtonPreview: View {
    let npc: NPC
    
    var body: some View {
        VStack(spacing: 2) {
            Text(npc.sex == .male ? "♂" : "♀")
                .font(.title3)
                .foregroundColor(npc.sex == .male ? .green : .purple)
            
            if npc.isUnknown {
                HStack{
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
        }
        .padding(8)
        .frame(width: 180)
        .background(Theme.secondaryColor.opacity(0.7))
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}

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
