import SwiftUI

struct LoveScene: View {
    // ViewModel to manage internal animation state
    @StateObject private var viewModel = LoveSceneViewModel()
    
    // Overall view opacity for fade-in/out (controlled externally)
    @State private var viewOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
                .opacity(viewOpacity * 0.9)
            
            DustEmitterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                   .edgesIgnoringSafeArea(.all)

            Image("loveSign")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
                // Read properties from viewModel
                .scaleEffect(viewModel.scale)
                .opacity(viewModel.iconOpacity)
                .blur(radius: viewModel.blurRadius)
                .shadow(color: .red.opacity(0.5), radius: viewModel.shadowRadius)
        }
        .opacity(viewOpacity) // Apply overall fade opacity to the ZStack
        .onAppear {
            // Animate fade-in
            withAnimation(.easeIn(duration: 0.5)) {
                viewOpacity = 1.0 
            }
            // Start internal pulsing animation
            viewModel.startAnimation()
        }
        .onDisappear {
            // Stop internal pulsing animation
            viewModel.stopAnimation()
            // Reset fade-out opacity (important if view might reappear)
            viewOpacity = 0.0
        }
    }
    
    // Removed startAnimation and stopAnimation methods from View
    // Removed state variables now managed by viewModel
} 
