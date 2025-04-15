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
    let onComplete: (Int) -> Void
    let npc: NPC
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VampireGazeView(npc: npc)
            .onChange(of: npc.isIntimidated) { isIntimidated in
                if isIntimidated {
                    onComplete(100) // Success
                } else {
                    onComplete(0) // Failure
                }
            }
    }
}
