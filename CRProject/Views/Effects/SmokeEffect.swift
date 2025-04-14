import SwiftUI

struct SmokeParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
}

struct SmokeEffect: View {
    @State private var particles: [SmokeParticle] = []
    @State private var isAnimating = false
    
    let duration: Double
    
    init(duration: Double = 1.0) {
        self.duration = duration
    }
    
    private func generateParticles() -> [SmokeParticle] {
        var newParticles: [SmokeParticle] = []
        let particleCount = 20
        
        for _ in 0..<particleCount {
            let randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            let randomY = CGFloat.random(in: 0...UIScreen.main.bounds.height)
            let particle = SmokeParticle(
                position: CGPoint(x: randomX, y: randomY),
                scale: CGFloat.random(in: 0.2...1.0),
                opacity: Double.random(in: 0.3...0.7)
            )
            newParticles.append(particle)
        }
        
        return newParticles
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .blur(radius: 20)
                        .position(particle.position)
                }
            }
        }
        .onAppear {
            particles = generateParticles()
            withAnimation(.easeOut(duration: duration)) {
                for index in particles.indices {
                    let randomOffsetX = CGFloat.random(in: -100...100)
                    let randomOffsetY = CGFloat.random(in: -150...(-50))
                    particles[index].position.x += randomOffsetX
                    particles[index].position.y += randomOffsetY
                    particles[index].opacity = 0
                }
            }
        }
    }
} 

class DustView: UIView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        createDust()
    }
    
    private func createDust() {
        let emitter = CAEmitterLayer()
        
        // 1. Configure emitter frame and position
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterShape = .rectangle
        emitter.emitterSize = CGSize(width: bounds.width * 1.5, height: bounds.height * 1.5) // Extended beyond view bounds
        emitter.renderMode = .additive
        
        // 2. Particle configuration (keeping your preferred settings)
        let cell = CAEmitterCell()
        cell.birthRate = 80
        cell.lifetime = 10
        cell.lifetimeRange = 20
        cell.velocity = 30
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2 // Full 360-degree emission
        cell.scale = 0.0
        cell.scaleRange = 0.1
        cell.alphaSpeed = -0.4
        
        // 3. Add some randomness to particle birth location
        cell.emissionLongitude = .pi * 2 // Circular emission
        cell.xAcceleration = CGFloat.random(in: -0.5...0.5) // Gentle horizontal drift
        cell.yAcceleration = CGFloat.random(in: -0.2...0.2) // Slight vertical movement
        
        // 4. Create particle image
        cell.contents = createParticleImage().cgImage
        
        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
    }
    
    private func createParticleImage() -> UIImage {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            UIColor.white.withAlphaComponent(0.7).setFill()
            path.fill()
        }
    }
    
    // 5. Handle view resizing
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach {
            if let emitter = $0 as? CAEmitterLayer {
                emitter.frame = bounds
                emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
                emitter.emitterSize = CGSize(width: bounds.width * 1.5, height: bounds.height * 1.5)
            }
        }
    }
}

struct DustEmitterView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = DustView()
        view.backgroundColor = .clear // Critical!
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Ensure it fills the available space
        uiView.frame = CGRect(origin: .zero, size: uiView.superview?.bounds.size ?? .zero)
    }
}
