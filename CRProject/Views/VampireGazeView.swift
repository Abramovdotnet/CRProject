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
    
    private let gazeSystem = VampireGazeSystem.shared
    
    init(npc: NPC, isPresented: Binding<Bool> = .constant(true)) {
        self.npc = npc
        _isPresented = isPresented
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Solid Black Background Base
                Color.black
                    .opacity(0.9)
                    .ignoresSafeArea()
                
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
                    Spacer()
                    
                    // NPC Info Card
                    VStack(spacing: 8) {
                        Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.bodyFont)
                            .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                        
                        // Character icon and blood meter
                        if npc.isUnknown {
                            Text(npc.isVampire ? "Vampire" : "Mortal")
                                .font(Theme.bodyFont)
                                .foregroundColor(npc.isVampire ? Theme.primaryColor : .green)
                        } else {
                            
                            if !npc.isUnknown {
                                Text(npc.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }

                            if !npc.isUnknown {
                                Text(npc.profession.rawValue)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)
                                    .lineLimit(1)
                            }

                            HStack(spacing: 8) {
                                if npc.currentActivity == .sleep {
                                    Image(systemName: "moon.zzz.fill")
                                        .foregroundColor(.blue)
                                        .font(Theme.bodyFont)
                                }
                                if npc.isIntimidated {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(Theme.bloodProgressColor)
                                        .font(Theme.bodyFont)
                                }
                                
                                Image(systemName: "waveform.path.ecg")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.isAlive ? .green : Theme.primaryColor)
                                
                                HStack(spacing: 1) {
                                    ForEach(0..<5) { index in
                                        let segmentValue = Double(npc.bloodMeter.currentBlood) / 100.0
                                        let segmentThreshold = Double(index + 1) / 5.0
                                        
                                        Rectangle()
                                            .fill(segmentValue >= segmentThreshold ?
                                                  Theme.bloodProgressColor : Color.black.opacity(0.3))
                                            .frame(height: 2)
                                    }
                                }
                                .frame(width: 30)
                                
                                Text(npc.isVampire ? "Vampire" : "Mortal")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : .green)
                            }
                        }
                        
                        // Resistance Bar
                        VStack(spacing: 4) {
                            Text("Resistance to Dark Powers")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textColor)
                            
                            GradientProgressBar(value: gazeSystem.calculateNPCResistance(npc: npc))
                                .frame(width: 200, height: 5)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .red.opacity(0.4),
                                                .red.opacity(0.2),
                                                .red.opacity(0.4)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .frame(maxWidth: geometry.size.width * 0.5)
                    
                    Spacer()
                    
                    // Power Selection Area (Right Side)
                    VStack(spacing: 15) {
                        Text("Choose Your Dark Power")
                            .font(Theme.headingFont)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        VStack(spacing: 10) {
                            ForEach(VampireGazeSystem.GazePower.allCases, id: \.self) { power in
                                EnhancedPowerButton(
                                    power: power,
                                    isSelected: selectedPower == power,
                                    action: { attemptGazePower(power) },
                                    isCompact: true
                                )
                            }
                        }
                    }
                    .frame(maxWidth: geometry.size.width * 0.4)
                    
                    Spacer()
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
    
    private var visualEffect: some View {
        GeometryReader { geometry in
            ZStack {
                switch selectedPower {
                case .charm:
                    EnhancedRedMistEffect()
                case .mesmerize:
                    EnhancedHypnoticSpiralEffect()
                case .dominate:
                    EnhancedDarkTendrils()
                case .none:
                    EmptyView()
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

struct EnhancedPowerButton: View {
    let power: VampireGazeSystem.GazePower
    let isSelected: Bool
    let action: () -> Void
    var isCompact: Bool = false
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
            HStack(spacing: 20) {
                // Power icon with enhanced effects
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(power.color)
                        .blur(radius: 20)
                        .opacity(glowOpacity)
                    
                    // Icon background
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    power.color.opacity(0.3),
                                    Color.black.opacity(0.8)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(power.color, lineWidth: isSelected ? 2 : 1)
                        )
                    
                    // Power icon
                    Image(systemName: power.icon)
                        .font(Theme.bodyFont)
                        .foregroundColor(power.color)
                }
                .frame(width: isCompact ? 50 : 60, height: isCompact ? 50 : 60)
                
                // Power information
                VStack(alignment: .leading, spacing: isCompact ? 3 : 6) {
                    Text(power.rawValue.capitalized)
                        .font(Theme.headingFont)
                        .foregroundColor(power.color)
                        .shadow(color: power.color.opacity(0.5), radius: 3)
                    
                    Text(power.description)
                        .font(Theme.bodyFont)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, isCompact ? 20 : 25)
            .padding(.vertical, isCompact ? 8 : 10)
            .background(
                ZStack {
                    // Button background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                    
                    // Decorative border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    power.color.opacity(0.6),
                                    power.color.opacity(0.2),
                                    power.color.opacity(0.6)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                    
                    // Selection indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(power.color.opacity(0.8), lineWidth: 2)
                            .blur(radius: 2)
                    }
                }
            )
            .scaleEffect(scale * hoverScale)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoverScale = isHovered ? 1.02 : 1.0
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = isSelected ? 0.5 : 0.0
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
        self.value = max(0, min(value, 100)) // Clamp value to 0-100
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
                        .fill(barColor) // Use flat color
                        .frame(width: calculateWidth(containerWidth: geometry.size.width))
                        .overlay(glowOverlay())
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // Helper to calculate width based on container
    private func calculateWidth(containerWidth: CGFloat) -> CGFloat {
        return containerWidth * CGFloat(value / 100.0)
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

