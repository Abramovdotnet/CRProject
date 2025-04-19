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
            Text("Day \(viewModel.currentDay)")
                .font(Theme.smallFont)
            
            Image(systemName: viewModel.currentScene?.sceneType.iconName ?? "")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)
            Text("\(viewModel.currentScene?.sceneType.displayName ?? "Unknown")")
                .foregroundColor(Theme.textColor)
                .font(Theme.smallFont)
            Text(viewModel.currentScene?.name ?? "Unknown")
                .font(Theme.smallFont)
        
            if viewModel.getPlayer().hiddenAt != .none {
                Image(systemName: viewModel.getPlayer().hiddenAt.iconName)
                    .foregroundColor(Theme.textColor)
                    .font(Theme.smallFont)
                Text(viewModel.getPlayer().hiddenAt.description)
                    .foregroundColor(Theme.textColor)
                    .font(Theme.smallFont)
            }
            
            Text("Population: \(viewModel.npcs.count)")
                .foregroundColor(Theme.textColor)
                .font(Theme.smallFont)

            Text("Awareness: \(Int(viewModel.sceneAwareness))%")
                .font(Theme.smallFont)
            ProgressBar(value: Double(viewModel.sceneAwareness / 100.0), color: Theme.awarenessProgressColor)
                .frame(width: 60)    
            
            Text("Blood: \(Int(viewModel.playerBloodPercentage))%")
                .font(Theme.smallFont)
            ProgressBar(value: Double(viewModel.playerBloodPercentage / 100), color: Theme.bloodProgressColor)
                .frame(width: 60)
            
            
            Text("Desires: ")
                .font(Theme.smallFont)
            
            if viewModel.getPlayer().desiredVictim.desiredSex != nil {
                Image(systemName: viewModel.getPlayer().desiredVictim.desiredSex == .female ? "figure.stand.dress" : "figure.wave")
                    .font(Theme.smallFont)
                    .foregroundColor(Color.yellow)
            }
            if viewModel.getPlayer().desiredVictim.desiredAgeRange != nil {
                Text(viewModel.getPlayer().desiredVictim.desiredAgeRange?.rangeDescription ?? "" + "Age")
                    .font(Theme.smallFont)
                    .foregroundColor(Color.yellow)
            }
            if viewModel.getPlayer().desiredVictim.desiredProfession != nil {
                Image(systemName: viewModel.getPlayer().desiredVictim.desiredProfession?.icon ?? "")
                    .font(Theme.smallFont)
                    .foregroundColor(Color.yellow)
            }
            if viewModel.getPlayer().desiredVictim.desiredMorality != nil {
                Image(systemName: viewModel.getPlayer().desiredVictim.desiredMorality?.icon ?? "")
                    .font(Theme.smallFont)
                    .foregroundColor(Color.yellow)
            }
            if viewModel.getPlayer().desiredVictim.desiredMotivation != nil {
                Image(systemName: viewModel.getPlayer().desiredVictim.desiredMotivation?.icon ?? "")
                    .font(Theme.smallFont)
                    .foregroundColor(Color.yellow)
            }
            
            Spacer()
            
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
