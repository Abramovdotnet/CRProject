import SwiftUI

struct PulsingEffect: ViewModifier {
    @State private var opacity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    opacity = 1.0
                }
            }
    }
}

struct HypnosisGameView: View {
    enum GameSymbol: String, CaseIterable {
        case bloodPulse = "heart.fill"
        case hypnosisGaze = "eye.fill"
        case vampireBite = "bolt.fill"
        
        var color: Color {
            Theme.bloodProgressColor
        }
    }
    
    let onComplete: (Int) -> Void
    let symbolSpeed: Double = 1.0 // Adjustable (1.0 = default speed)
    let maxSymbolScale: CGFloat = 2.0 // Adjustable maximum size
    let npc: NPC // Add NPC parameter
    
    @State private var activeSymbols: [SymbolData] = []
    @State private var pulsePhase = 0.0
    @State private var score = 50 // Starting at 50
    @State private var showSuccess = false
    @State private var showFail = false
    @State private var showResult = false
    @State private var progressValue: Double = 0.5 // Starting at 50%
    @State private var isProgressBarBlinking = false
    @State private var progressBarOpacity: Double = 1.0
    @State private var heartOpacity: Double = 1.0
    @State private var watchScale: CGFloat = 1.0
    @State private var artImage: String
    @Environment(\.dismiss) private var dismiss
    
    init(onComplete: @escaping (Int) -> Void, npc: NPC) {
        self.onComplete = onComplete
        self.npc = npc
        let randomNumber = Int.random(in: 1...8)
        self._artImage = State(initialValue: "deviantArt\(randomNumber)")
    }
    
    private struct SymbolData: Identifiable {
        let id = UUID()
        let symbol: GameSymbol
        var position: CGPoint
        var scale: CGFloat = 1.0
        var opacity: Double = 1.0
        var color: Color = Theme.textColor
    }
    
    private var resultView: some View {
        GeometryReader { geometry in
            ZStack {
                // Static black background
                Color.black
                    .ignoresSafeArea()
                
                // Animated overlay
                Color.black
                    .opacity(0.9)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack {
                    // Black background for image
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                            .frame(maxWidth: geometry.size.width)
                            .aspectRatio(1, contentMode: .fit)
                        
                        Image(artImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.white)
                            .modifier(PulsingEffect())
                            .transition(.opacity)
                    }
                    completeButton
                }
            }
            .transition(.opacity)
        }
    }
    
    private var completeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                watchScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring()) {
                    watchScale = 1.0
                    VibrationService.shared.lightTap()
                    onComplete(score)
                }
            }
        }) {
            ZStack {
                // 1. Frame (bottom layer)
                Image("iconFrame")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50 * 1.1, height: 50 * 1.1)
                
                // 2. Background circle (middle layer)
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 50 * 0.85, height: 50 * 0.85)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: "heart.fill")
                    .foregroundColor(Theme.bloodProgressColor)
                    .font(.system(size: 20))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50 * 0.8, height: 50 * 0.8)
            }
            .scaleEffect(watchScale)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
        .shadow(color: .black, radius: 3, x: 0, y: 2)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !showResult {
                    Image("MainSceneBackground")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                }
                
                if showResult {
                    resultView
                }
                
                if !showResult {
                    gameContent(geometry: geometry)
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: score) { newScore in
            withAnimation(.easeInOut(duration: 0.3)) {
                progressValue = Double(newScore) / 100.0
            }
            
            // Start/stop blinking based on score
            if newScore <= 40 && !isProgressBarBlinking {
                startProgressBarBlinking()
            } else if newScore > 40 && isProgressBarBlinking {
                stopProgressBarBlinking()
            }
            
            if newScore >= 100 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if npc.sex == .male {
                        showSuccess = true
                        onComplete(score)
                    } else {
                        showResult = true
                    }
                }
                VibrationService.shared.successVibration()
            } else if newScore <= 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dismiss()
                }
            }
        }
        .onAppear {
            startGame()
            startHeartPulsing()
        }
    }
    
    private func gameContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Progress bar at the top
            progressBar(geometry: geometry)
            
            Spacer()
            
            // Game content
            ZStack {
                // Heartbeat line layers
                heartbeatLayers
                
                // Moving symbols
                ForEach(activeSymbols) { symbol in
                    Image(systemName: symbol.symbol.rawValue)
                        .foregroundColor(symbol.color)
                        .font(.title)
                        .scaleEffect(symbol.scale)
                        .opacity(symbol.opacity)
                        .position(symbol.position)
                        .padding(.top, -28)
                }
            }
            .frame(height: 150)
            
            // Control icons
            controlButtons
        }
        .transition(.opacity)
    }
    
    private var heartbeatLayers: some View {
        ZStack {
            HeartbeatLine(phase: pulsePhase)
                .stroke(Theme.bloodProgressColor, lineWidth: 4)
                .opacity(0.15)
                .frame(height: 100)
                .padding(.horizontal)
                .blur(radius: 8)
            
            HeartbeatLine(phase: pulsePhase)
                .stroke(Theme.bloodProgressColor, lineWidth: 3)
                .opacity(0.2)
                .frame(height: 100)
                .padding(.horizontal)
                .blur(radius: 4)
            
            HeartbeatLine(phase: pulsePhase)
                .stroke(Theme.bloodProgressColor, lineWidth: 2)
                .opacity(0.3)
                .frame(height: 100)
                .padding(.horizontal)
                .shadow(color: Theme.bloodProgressColor, radius: 2, x: 0, y: 0)
            
            HeartbeatLine(phase: pulsePhase)
                .stroke(Theme.bloodProgressColor, lineWidth: 1.5)
                .frame(height: 100)
                .padding(.horizontal)
        }
    }
    
    private func progressBar(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .leading) {
            // Background track (inactive part)
            Rectangle()
                .foregroundColor(.black.opacity(0.5))
            
            // Progress fill (active part)
            Rectangle()
                .foregroundColor(Theme.bloodProgressColor)
                .frame(width: geometry.size.width * CGFloat(progressValue))
                .opacity(progressBarOpacity)
        }
        .frame(height: 20)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1)
                .opacity(0.5)
        )
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var controlButtons: some View {
        HStack(spacing: 30) {
            ForEach(GameSymbol.allCases, id: \.self) { symbol in
                Button(action: {
                    checkSymbolMatch(symbol)
                }) {
                    Image(systemName: symbol.rawValue)
                        .font(.system(size: 30))
                        .foregroundColor(Theme.bloodProgressColor)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.bloodProgressColor, lineWidth: 2)
                        )
                }
            }
        }
        .padding(.bottom, 130)
    }
    
    private func startGame() {
        // Start pulse animation synchronized with symbol speed
        pulsePhase = 0
        withAnimation(
            Animation
                .linear(duration: 1.5 / symbolSpeed)
                .repeatForever(autoreverses: false)
        ) {
            pulsePhase = 1.0
        }
        
        // Spawn symbols
        Timer.scheduledTimer(withTimeInterval: 1.5/symbolSpeed, repeats: true) { _ in
            spawnSymbol()
        }
        
        // Update symbol positions
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateSymbols()
        }
        
        // Score decay timer (10 seconds for full bar)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if score > 0 && score < 100 {
                score -= 1 // Decrease by 1 every 0.1 seconds = 100 points in 10 seconds
            }
        }
    }
    
    private func spawnSymbol() {
        let screenWidth = UIScreen.main.bounds.width
        let newSymbol = SymbolData(
            symbol: GameSymbol.allCases.randomElement()!,
            position: CGPoint(x: screenWidth - 50, y: UIScreen.main.bounds.midY)
        )
        activeSymbols.append(newSymbol)
    }
    
    private func updateSymbols() {
        let centerX = UIScreen.main.bounds.midX
        
        for index in activeSymbols.indices {
            // Move left
            activeSymbols[index].position.x -= 3 * symbolSpeed
            
            // Calculate distance from center
            let distance = abs(activeSymbols[index].position.x - centerX)
            
            // Scale and color based on distance to center
            let maxDistance = UIScreen.main.bounds.width/2
            let normalizedDistance = min(distance/maxDistance, 1.0)
            activeSymbols[index].scale = maxSymbolScale * (1 - normalizedDistance)
            
            // Interpolate color from text to blood color
            activeSymbols[index].color = normalizedDistance > 0.2 ? 
                Theme.textColor : 
                Theme.bloodProgressColor
            
            // Remove if off screen
            if activeSymbols[index].position.x < -50 {
                // Penalize missed symbols
                if distance < hitZoneWidth {
                    score -= 5
                }
                activeSymbols.remove(at: index)
                return
            }
        }
    }
    
    private let hitZoneWidth: CGFloat = 50
    
    private func checkSymbolMatch(_ tappedSymbol: GameSymbol) {
        // Ignore input if game is completed or in transition
        guard !showResult else { return }
        
        let centerX = UIScreen.main.bounds.midX
        
        // Check if we're about to reach 100 points
        let potentialScore = score + (tappedSymbol == .vampireBite ? 40 : 30)
        if potentialScore >= 100 {
            score = 100
            withAnimation(.easeInOut(duration: 0.5)) {
                showResult = true
            }
            VibrationService.shared.successVibration()
            return
        }
        
        for index in activeSymbols.indices.reversed() {
            let symbol = activeSymbols[index]
            let distance = abs(symbol.position.x - centerX)
            
            if distance < hitZoneWidth {
                if symbol.symbol == tappedSymbol {
                    // Successful hit
                    score = min(score + (symbol.symbol == .vampireBite ? 40 : 30), 100)
                    
                    withAnimation {
                        activeSymbols[index].scale *= 1.5
                        activeSymbols[index].opacity = 0
                        showSuccess = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if index < activeSymbols.count {
                            activeSymbols.remove(at: index)
                        }
                        showSuccess = false
                    }
                    
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    return
                } else {
                    // Wrong symbol penalty
                    score = max(0, score - 20)
                }
            }
        }
        
        // Failed hit
        withAnimation {
            showFail = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showFail = false
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    private func startProgressBarBlinking() {
        isProgressBarBlinking = true
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            progressBarOpacity = 0.3
        }
    }
    
    private func stopProgressBarBlinking() {
        isProgressBarBlinking = false
        withAnimation(.easeInOut(duration: 0.3)) {
            progressBarOpacity = 1.0
        }
    }
    
    private func startHeartPulsing() {
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            heartOpacity = 0.3
        }
    }
}

struct HeartbeatLine: Shape {
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height * 0.5
        let amplitude = height * 0.4
        
        // Create a single heartbeat cycle
        func heartbeatCycle(startX: CGFloat, seed: Int) -> Path {
            var beat = Path()
            let cycleWidth: CGFloat = 500
            
            // Enhanced randomization with multiple seeds
            let randomWithModifier = { (min: CGFloat, max: CGFloat, modifier: Int) -> CGFloat in
                let h1 = Double(abs((seed &+ modifier) &* 1103515245 + 12345))
                let h2 = Double(abs((seed &+ modifier) &* 27182818 + 31415926))
                let hash = h1 + h2 * 0.5
                return min + CGFloat(hash.truncatingRemainder(dividingBy: 1.0)) * (max - min)
            }
            
            // Wrapper function for optional modifier
            func random(_ min: CGFloat, _ max: CGFloat, modifier: Int = 0) -> CGFloat {
                return randomWithModifier(min, max, modifier)
            }
            
            // Start with flat line
            beat.move(to: CGPoint(x: startX, y: midY))
            
            // Randomize baseline position slightly
            let baselineVariation = random(-2, 2, modifier: 1)
            let flatLength = random(300, 450, modifier: 2)
            beat.addLine(to: CGPoint(x: startX + flatLength, y: midY + baselineVariation))
            
            let spikeStart = startX + flatLength
            let spikeWidth = random(8, 25, modifier: 3)
            
            // Randomly choose spike pattern
            let patternType = Int(random(0, 4, modifier: 4))
            
            switch patternType {
            case 0: // Classic V spike
                // Down spike
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth, y: midY + amplitude * random(0.2, 0.4, modifier: 5)))
                // Up spike
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 1.5, y: midY - amplitude * random(0.8, 1.2, modifier: 6)))
                // Return
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 2, y: midY + baselineVariation))
                
            case 1: // Sharp peak with pre-wave
                // Small pre-wave
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 0.3, y: midY - amplitude * random(0.1, 0.2, modifier: 7)))
                // Down to baseline
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 0.6, y: midY))
                // Main spike
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 1.2, y: midY - amplitude * random(0.9, 1.1, modifier: 8)))
                // Sharp return
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 1.8, y: midY + baselineVariation))
                
            case 2: // Double peak
                // First peak
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 0.5, y: midY - amplitude * random(0.5, 0.7, modifier: 9)))
                // Valley
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth, y: midY + amplitude * random(0.2, 0.3, modifier: 10)))
                // Second peak
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 1.5, y: midY - amplitude * random(0.8, 1.0, modifier: 11)))
                // Return
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 2, y: midY + baselineVariation))
                
            default: // Asymmetric spike
                // Slow rise
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 0.7, y: midY - amplitude * random(0.3, 0.5, modifier: 12)))
                // Sharp peak
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 1.2, y: midY - amplitude * random(0.9, 1.1, modifier: 13)))
                // Quick drop
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 1.5, y: midY + amplitude * random(0.2, 0.4, modifier: 14)))
                // Return to baseline
                beat.addLine(to: CGPoint(x: spikeStart + spikeWidth * 2, y: midY + baselineVariation))
            }
            
            // Continue with flat line to end of cycle
            beat.addLine(to: CGPoint(x: startX + cycleWidth, y: midY + baselineVariation))
            
            return beat
        }
        
        // Add multiple heartbeat cycles
        let cycleWidth: CGFloat = 500
        let numCycles = Int(width / cycleWidth) + 2
        let offset = -cycleWidth * CGFloat(phase)
        
        for i in -1..<numCycles {
            let startX = CGFloat(i) * cycleWidth + offset
            path.addPath(heartbeatCycle(startX: startX, seed: i))
        }
        
        return path
    }
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
}
