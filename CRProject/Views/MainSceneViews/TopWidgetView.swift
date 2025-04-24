import SwiftUI

// MARK: - Top Widget
struct TopWidgetView: View {
    @ObservedObject var viewModel: MainSceneViewModel

    var body: some View {
        // Keep the outer check for player existence if needed for other properties
        if let player = viewModel.player { 
            HStack {
                // World Info
                Image(systemName: viewModel.isNight ? "moon.fill" : "sun.max.fill")
                    .font(Theme.bodyFont)
                    .foregroundColor(viewModel.isNight ? .white : .yellow)
                Text(" \(viewModel.currentHour):00")
                    .font(Theme.bodyFont)
                    .padding(.leading, -5)
                Text("Day \(viewModel.currentDay)")
                    .font(Theme.bodyFont)
                    .padding(.leading, -5)
                
                if viewModel.currentScene?.isLocked == true {
                        Image(systemName: "lock.fill")
                             .foregroundColor(Theme.accentColor)
                             .font(Theme.bodyFont)
                    }
                Image(systemName: viewModel.currentScene?.sceneType.iconName ?? "")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                Text(viewModel.currentScene?.name ?? "Unknown")
                    .foregroundColor(.yellow)
                    .font(Theme.bodyFont)
                    .padding(.leading, -5)
            
                // Use unwrapped player
                if player.hiddenAt != .none {
                    Image(systemName: player.hiddenAt.iconName)
                        .foregroundColor(Theme.textColor)
                        .font(Theme.bodyFont)
                    Text(player.hiddenAt.description)
                        .foregroundColor(Theme.textColor)
                        .font(Theme.bodyFont)
                }
                
                Image(systemName: "person.3.fill")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                Text("\(viewModel.npcs.count)")
                    .foregroundColor(Theme.textColor)
                    .font(Theme.bodyFont)
                    .padding(.leading, -5)
                
                Image(systemName: "figure.walk.triangle.fill")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.awarenessProgressColor)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                Text("\(Int(viewModel.sceneAwareness))%")
                    .font(Theme.bodyFont)
                    .padding(.leading, -5)
                ProgressBar(value: Double(viewModel.sceneAwareness / 100.0), color: Theme.awarenessProgressColor)
                    .frame(width: 100)
                    .padding(.leading, -5)
                
                Image(systemName: "drop.fill")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.bloodProgressColor)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                // Use player directly for blood percentage if available
                Text("\(Int(player.bloodMeter.bloodPercentage))%")
                    .font(Theme.bodyFont)
                    .padding(.leading, -5)
                ProgressBar(value: Double(player.bloodMeter.bloodPercentage / 100), color: Theme.bloodProgressColor)
                    .frame(width: 100)
                    .padding(.leading, -5)
                
                Image(systemName: "cedisign")
                    .font(Theme.bodyFont)
                    .foregroundColor(.green)
                
                // Display the simple published value from the ViewModel
                Text("\(viewModel.playerCoinsValue)") 
                    .font(Theme.bodyFont)
                    .foregroundColor(.green)
                
                // --- Debug Buttons (Consider removing or disabling in production) ---
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
                    viewModel.resetBloodPool()
                }) {
                    Image(systemName: "heart.fill")
                        .font(Theme.bodyFont)
                        .foregroundColor(.yellow)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.resetDesires()
                }) {
                    Image(systemName: "w.circle")
                        .font(Theme.bodyFont)
                        .foregroundColor(.yellow)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.toggleDebugOverlay()
                }) {
                    Image(systemName: "hammer.fill")
                        .font(Theme.bodyFont)
                        .foregroundColor(.yellow)
                        .cornerRadius(12)
                }
                // --- End Debug Buttons ---
            }
            .padding(.top, 5)
            .padding(.bottom, 5)
        } else {
            // Optional: Show a placeholder or loading state if player is nil
            HStack {
                 Text("Loading player data...")
                    .font(Theme.bodyFont)
                    .foregroundColor(.gray)
            }
            .padding(.top, 5)
            .padding(.bottom, 5)
        }
    }
}
