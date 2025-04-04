import SwiftUI

struct LightningView: View {
    @State private var phase: CGFloat = 0
    @State private var lightningPoints: [CGPoint] = []
    let centerX: CGFloat = UIScreen.main.bounds.width / 2
    let radius: CGFloat = 100
    let updateInterval: TimeInterval = 1 / 120 // 120 FPS
    
    var body: some View {
        Canvas { context, size in
            guard !lightningPoints.isEmpty else { return }
            
            // Рисуем молнию
            var path = Path()
            path.move(to: CGPoint(x: centerX, y: size.height / 2))
            
            for point in lightningPoints {
                path.addLine(to: point)
            }
            
            // Стиль молнии
            context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [.red, .orange]),
                                startPoint: .zero,
                                endPoint: CGPoint(x: 0, y: size.height)
                            ),
                            lineWidth: 1.5
                        )
            
            // Добавляем свечение
            context.blendMode = .plusLighter
            context.stroke(
                path,
                with: .color(.red.opacity(0.3)),
                lineWidth: 8
            )
        }
        .onAppear {
            startAnimation()
        }
    }
    
    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            withAnimation(.linear(duration: updateInterval)) {
                phase += 0.02
                updateLightningPoints()
            }
        }
    }
    
    func updateLightningPoints() {
        let centerY = UIScreen.main.bounds.height / 2
        let endPoint = CGPoint(
            x: centerX + radius * cos(phase),
            y: centerY + radius * sin(phase)
        )
        
        // Генерация точек молнии
        var points: [CGPoint] = []
        let segments = 20
        let jitter: CGFloat = 15
        
        for i in 0..<segments {
            let progress = CGFloat(i) / CGFloat(segments - 1)
            let baseX = centerX + (endPoint.x - centerX) * progress
            let baseY = centerY + (endPoint.y - centerY) * progress
            
            // Добавляем "дрожание" для эффекта молнии
            let offsetX = CGFloat.random(in: -jitter...jitter) * (1 - progress)
            let offsetY = CGFloat.random(in: -jitter...jitter) * (1 - progress)
            
            points.append(CGPoint(
                x: baseX + offsetX,
                y: baseY + offsetY
            ))
        }
        
        // Эффект мерцания
        if Int.random(in: 0..<10) < 3 {
            points = points.map { point in
                CGPoint(
                    x: point.x + CGFloat.random(in: -5...5),
                    y: point.y + CGFloat.random(in: -5...5)
                )
            }
        }
        
        lightningPoints = points
    }
}
