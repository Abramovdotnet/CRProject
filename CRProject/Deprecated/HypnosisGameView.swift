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
