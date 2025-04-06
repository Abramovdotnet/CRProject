import SwiftUI

// MARK: - Top Widget
struct TopWidgetView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    
    var body: some View {
        HStack {
            // World Info
            Image(systemName: viewModel.isNight ? "moon.fill" : "sun.max.fill")
                .font(Theme.bodyFont)
                .foregroundColor(viewModel.isNight ? .white : .yellow)
            Text(" \(viewModel.currentHour):00")
                .font(Theme.headingFont)
            Text("Day \(viewModel.currentDay)")
                .font(Theme.bodyFont)
            
            Spacer()
            
            Text("Blood: \(Int(viewModel.playerBloodPercentage))%")
                .font(Theme.bodyFont)
            ProgressBar(value: Double(viewModel.playerBloodPercentage / 100.0), color: Theme.bloodProgressColor)
            
            Spacer()
            
            if let scene = viewModel.currentScene,
               scene.name.lowercased().contains("tavern"),
               !viewModel.isNight,
               viewModel.isAwarenessSafe {
                Button(action: {
                    viewModel.skipTimeToNight()
                }) {
                    Image(systemName: "moon.fill")
                        .font(Theme.bodyFont)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            Button(action: {
                viewModel.respawnNPCs()
            }) {
                Image(systemName: "figure.walk")
                    .font(Theme.bodyFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
            Button(action: {
                viewModel.resetAwareness()
            }) {
                Image(systemName: "figure.walk.diamond")
                    .font(Theme.bodyFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
            
            Button(action: {
                viewModel.toggleDebugOverlay()
            }) {
                Image(systemName: "hammer.fill")
                    .font(Theme.bodyFont)
                    .foregroundColor(.orange)
                    .cornerRadius(12)
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 5)
    }
}
