import SwiftUI

struct EndGameView: View {
    let statistics: StatisticsService = DependencyManager.shared.resolve()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                Text("You discovered yourself. People caught you, burned, decapitated and buried into the ground.")
                    .font(.title3)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .center, spacing: 15) {
                    StatRow(title: "Days Survived", value: statistics.daysSurvived)
                    StatRow(title: "Feedings", value: statistics.feedings)
                    StatRow(title: "Victims Drained", value: statistics.victimsDrained)
                    StatRow(title: "People Killed", value: statistics.peopleKilled)
                }
                .padding()
                
                Button("Exit") {
                    MainSceneView(viewModel: MainSceneViewModel())
                    dismiss
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 20)
            }
            .padding()
        }
    }
}

struct StatRow: View {
    let title: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.red)
            Spacer()
            Text("\(value)")
                .font(.title2)
                .foregroundColor(.red)
        }
        .frame(width: 200)
    }
}
