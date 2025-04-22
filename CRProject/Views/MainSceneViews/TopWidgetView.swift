import SwiftUI

// MARK: - Top Widget
struct TopWidgetView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    
    var body: some View {
        HStack {
            // World Info
            Image(systemName: viewModel.isNight ? "moon.fill" : "sun.max.fill")
                .font(Theme.smallFont)
                .foregroundColor(viewModel.isNight ? .white : .yellow)
            Text(" \(viewModel.currentHour):00")
                .font(Theme.smallFont)
                .padding(.leading, -5)
            Text("Day \(viewModel.currentDay)")
                .font(Theme.smallFont)
                .padding(.leading, -5)
            
            if viewModel.currentScene?.isLocked == true {
                    Image(systemName: "lock.fill")
                         .foregroundColor(Theme.accentColor)
                         .font(Theme.smallFont)
                }
            Image(systemName: viewModel.currentScene?.sceneType.iconName ?? "")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)
            Text(viewModel.currentScene?.name ?? "Unknown")
                .foregroundColor(.yellow)
                .font(Theme.smallFont)
                .padding(.leading, -5)
        
            if viewModel.getPlayer().hiddenAt != .none {
                Image(systemName: viewModel.getPlayer().hiddenAt.iconName)
                    .foregroundColor(Theme.textColor)
                    .font(Theme.smallFont)
                Text(viewModel.getPlayer().hiddenAt.description)
                    .foregroundColor(Theme.textColor)
                    .font(Theme.smallFont)
            }
            
            Image(systemName: "person.3.fill")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            Text("\(viewModel.npcs.count)")
                .foregroundColor(Theme.textColor)
                .font(Theme.smallFont)
                .padding(.leading, -5)
            
            Image(systemName: "figure.walk.triangle.fill")
                .font(Theme.smallFont)
                .foregroundColor(Theme.awarenessProgressColor)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            Text("\(Int(viewModel.sceneAwareness))%")
                .font(Theme.smallFont)
                .padding(.leading, -5)
            ProgressBar(value: Double(viewModel.sceneAwareness / 100.0), color: Theme.awarenessProgressColor)
                .frame(width: 100)
                .padding(.leading, -5)
            
            Image(systemName: "drop.fill")
                .font(Theme.smallFont)
                .foregroundColor(Theme.bloodProgressColor)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            Text("\(Int(viewModel.playerBloodPercentage))%")
                .font(Theme.smallFont)
                .padding(.leading, -5)
            ProgressBar(value: Double(viewModel.playerBloodPercentage / 100), color: Theme.bloodProgressColor)
                .frame(width: 100)
                .padding(.leading, -5)
            
            Button(action: {
                viewModel.respawnNPCs()
            }) {
                Image(systemName: "figure.walk")
                    .font(Theme.smallFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
            Button(action: {
                viewModel.resetAwareness()
            }) {
                Image(systemName: "figure.walk.diamond")
                    .font(Theme.smallFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
            
            Button(action: {
                viewModel.resetBloodPool()
            }) {
                Image(systemName: "heart.fill")
                    .font(Theme.smallFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
            
            Button(action: {
                viewModel.resetDesires()
            }) {
                Image(systemName: "w.circle")
                    .font(Theme.smallFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
            
            Button(action: {
                viewModel.toggleDebugOverlay()
            }) {
                Image(systemName: "hammer.fill")
                    .font(Theme.smallFont)
                    .foregroundColor(.yellow)
                    .cornerRadius(12)
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 5)
    }
}
