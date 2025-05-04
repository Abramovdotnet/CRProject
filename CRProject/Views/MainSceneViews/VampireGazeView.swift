//
//  VampireGazeView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 13.04.2025.
//

import SwiftUI

struct VampireGazeView: View {
    let npc: NPC
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @State private var selectedPower: VampireGazeSystem.GazePower?
    @State private var showingEffect = false
    @State private var effectOpacity = 0.0
    @State private var backgroundOpacity = 0.0
    @State private var contentOpacity = 0.0
    @State private var moonPhase: Double = 0.0
    
    @ObservedObject var mainViewModel: MainSceneViewModel
    
    private let gazeSystem = VampireGazeSystem.shared
    
    init(npc: NPC, isPresented: Binding<Bool> = .constant(true), mainViewModel: MainSceneViewModel) {
        self.npc = npc
        _isPresented = isPresented
        self.mainViewModel = mainViewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Solid Black Background Base
                Color.black
                    .ignoresSafeArea()
                
                Image("gaze")
                    .resizable()
                    .ignoresSafeArea()
                    .opacity(0.7)
                
                DustEmitterView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                       .edgesIgnoringSafeArea(.all)
                
                // Blood moon effect
                BloodMoonEffect(phase: moonPhase)
                    .opacity(backgroundOpacity * 0.8)
                    .ignoresSafeArea()
              
                // Blood mist effect
                EnhancedBloodMistEffect()
                    .opacity(0.4)
                    .ignoresSafeArea()
                
                // Main Content (Horizontal Layout)
                HStack(alignment: .center, spacing: 20) {
                    // NPC Info Card (Left Side)
                    NPCWidget(npc: npc, isSelected: false, isDisabled: false, showResistance: true, onTap: { Void() }, onAction: { _ in Void ()})
                        .padding(.top, 40)
                    
                    // Power Selection Area (Right Side)
                    VStack(spacing: 15) {
                        Text("Choose Your Dark Power")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        // Grid layout for power buttons
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(VampireGazeSystem.GazePower.availableCases(npc: npc), id: \.self) { power in
                                let data = EnhancedPowerButtonData(
                                    power: power,
                                    isSelected: selectedPower == power,
                                    isDisabled: power.cost > mainViewModel.playerBloodPercentage
                                )
                                
                                EnhancedPowerButton(
                                    data: data,
                                    action: { attemptGazePower(power) }
                                )
                                .frame(height: 65)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: geometry.size.width * 0.7)
                    .padding(.horizontal, 16)
                }
                .padding()
                .opacity(contentOpacity)
                
                // Visual effect overlay
                if showingEffect {
                    visualEffect
                        .opacity(effectOpacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            
            TopWidgetView(viewModel: mainViewModel)
                .frame(maxWidth: .infinity)
                .padding(.top, geometry.safeAreaInsets.top)
                .foregroundColor(Theme.textColor)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                backgroundOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                contentOpacity = 1
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                moonPhase = 1
            }
        }
    }
    
    private func getNPCImage() -> Image {
        if npc.isUnknown {
            return Image(uiImage: UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        } else {
            return Image(uiImage: UIImage(named: "npc\(npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        }
    }
    
    private var visualEffect: some View {
        GeometryReader { geometry in
            ZStack {
                switch selectedPower {
                case .seduction:
                    EnhancedRedMistEffect()
                case .command:
                    EnhancedHypnoticSpiralEffect()
                case .dominate:
                    EnhancedDarkTendrils()
                case .scare:
                    EnhancedPurpleMistEffect()
                case .follow:
                    EnhancedHypnoticSpiralEffect()
                case .none:
                    EmptyView()
                case .some(.release):
                    EnhancedHypnoticSpiralEffect()
                case .some(.dreamstealer):
                    EnhancedRedMistEffect()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func attemptGazePower(_ power: VampireGazeSystem.GazePower) {
        selectedPower = power
        showingEffect = true
        VibrationService.shared.lightTap()
        
        let success = gazeSystem.attemptGazePower(power: power, on: npc)
        
        if let player = GameStateService.shared.player {
            player.bloodMeter.useBlood(power.cost)
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            effectOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                effectOpacity = 0
                if success {
                    VibrationService.shared.successVibration()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    contentOpacity = 0
                    backgroundOpacity = 0
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Enhanced Components

struct EnhancedPowerButtonData {
    let power: VampireGazeSystem.GazePower
    let isSelected: Bool
    var isDisabled: Bool
}
struct EnhancedPowerButton: View {
    let data: EnhancedPowerButtonData
    let action: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var hoverScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            action()
        }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(data.power.color)
                        .blur(radius: 15)
                        .opacity(glowOpacity)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    data.power.color.opacity(0.3),
                                    Color.black.opacity(0.8)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: data.power.icon)
                        .font(.system(size: 16))
                        .foregroundColor(data.power.color)
                }
                .frame(width: 36, height: 36)
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(data.power.description)
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Text("\(Int(data.power.cost))🩸")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.bloodProgressColor)
                            .padding(.leading, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(data.power.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(scale * hoverScale)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(data.isDisabled)
        .opacity(data.isDisabled ? 0.5 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoverScale = hovering ? 1.05 : 1.0
                glowOpacity = hovering ? 0.3 : 0.0
            }
        }
    }
}

struct GradientProgressBar: View {
    let value: Float // Value between 0.0 and 100.0
    let barColor: Color
    let useGradient: Bool
    let showGlow: Bool
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    // Updated initializer with more options
    init(value: Float,
         barColor: Color? = nil,
         useGradient: Bool = true,
         showGlow: Bool = true,
         backgroundColor: Color = Color.black.opacity(0.3),
         cornerRadius: CGFloat = 3)
    {
        self.value = value
        self.barColor = barColor ?? .red
        self.useGradient = useGradient
        self.showGlow = showGlow
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        GeometryReader { geometry in // Use GeometryReader for width
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(backgroundColor)
                    // Removed stroke overlay for simplicity, can be added back if needed
                
                // Fill
                if useGradient { // Apply conditional fill directly
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                barColor.opacity(0.8),
                                barColor,
                                barColor.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: calculateWidth(containerWidth: geometry.size.width))
                        .overlay(glowOverlay())
                } else {
                    Rectangle()
                        .fill(value > 0 ? barColor : Theme.bloodProgressColor)
                        .frame(width: calculateWidth(containerWidth: geometry.size.width))
                        .overlay(glowOverlay())
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // Helper to calculate width based on container
    private func calculateWidth(containerWidth: CGFloat) -> CGFloat {
        let absoluteValue = abs(value)
         return containerWidth * CGFloat(absoluteValue / 100.0)
    }

    // Helper for optional glow
    @ViewBuilder
    private func glowOverlay() -> some View {
        if showGlow {
            Rectangle()
                .fill(Color.white)
                .blur(radius: 8)
                .opacity(0.3) // Use fixed opacity or make it state-based if needed
                .blendMode(.screen)
        }
    }
}

struct BloodMoonEffect: View {
    let phase: Double
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        .red.opacity(0.8),
                        .red.opacity(0.3),
                        .clear
                    ]),
                    center: .center,
                    startRadius: 50,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
            .blur(radius: 20)
            .offset(x: -100, y: -150)
    }
}

struct EnhancedBloodMistEffect: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.addFilter(.blur(radius: 30))
                
                for i in 0..<15 {
                    var path = Path()
                    let offset = CGFloat(i) * 0.2 + phase
                    
                    for x in stride(from: 0, through: size.width, by: 20) {
                        let y = sin(x/60 + offset) * 40 + size.height/2
                        if x == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addQuadCurve(
                                to: CGPoint(x: x, y: y),
                                control: CGPoint(x: x - 10, y: y + 10 * sin(x/30 + offset))
                            )
                        }
                    }
                    
                    context.stroke(
                        path,
                        with: .color(.red.opacity(0.15)),
                        lineWidth: 30
                    )
                }
            }
            .onChange(of: timeline.date) { _ in
                phase += 0.02
            }
        }
    }
}

// MARK: - Visual Effects (Re-added)

struct EnhancedRedMistEffect: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.addFilter(.blur(radius: 30))
                
                for i in 0..<12 {
                    var path = Path()
                    let offset = CGFloat(i) * 0.2 + phase
                    
                    for x in stride(from: 0, through: size.width, by: 15) {
                        let y = sin(x/40 + offset) * 30 + size.height/2
                        if x == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    context.stroke(
                        path,
                        with: .color(.red.opacity(0.2)),
                        lineWidth: 25
                    )
                }
            }
            .onChange(of: timeline.date) { _ in
                phase += 0.02
            }
        }
    }
}


struct EnhancedPurpleMistEffect: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.addFilter(.blur(radius: 30))
                
                for i in 0..<12 {
                    var path = Path()
                    let offset = CGFloat(i) * 0.2 + phase
                    
                    for x in stride(from: 0, through: size.width, by: 15) {
                        let y = sin(x/40 + offset) * 30 + size.height/2
                        if x == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    context.stroke(
                        path,
                        with: .color(.purple.opacity(0.2)),
                        lineWidth: 25
                    )
                }
            }
            .onChange(of: timeline.date) { _ in
                phase += 0.02
            }
        }
    }
}

struct EnhancedHypnoticSpiralEffect: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let maxRadius = min(size.width, size.height) * 0.4
                
                for i in stride(from: 0, to: maxRadius, by: 8) {
                    var path = Path()
                    let startAngle = Angle(degrees: rotation + Double(i))
                    let endAngle = startAngle + .degrees(720)
                    
                    path.addArc(
                        center: center,
                        radius: i,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    
                    context.stroke(
                        path,
                        with: .color(.purple.opacity(0.3)),
                        lineWidth: 4
                    )
                }
            }
            .onChange(of: timeline.date) { _ in
                rotation += 3
            }
        }
    }
}

struct EnhancedDarkTendrils: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width/2, y: size.height/2)
                
                for i in 0..<12 {
                    var path = Path()
                    let angle = Double(i) * .pi * 2 / 12 + Double(phase)
                    
                    path.move(to: center)
                    for t in stride(from: 0, to: 1, by: 0.01) {
                        let radius = t * min(size.width, size.height) * 0.5
                        let x = center.x + cos(angle + t * 6) * radius
                        let y = center.y + sin(angle + t * 6) * radius
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(.orange.opacity(0.3)),
                        lineWidth: 2
                    )
                }
            }
            .onChange(of: timeline.date) { _ in
                phase += 0.05
            }
        }
    }
}

