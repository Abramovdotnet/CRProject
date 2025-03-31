import SwiftUI

struct DebugView: View {
    @StateObject private var viewModel = DebugViewViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Game Time Info
                VStack(alignment: .leading) {
                    Text("Game Time: \(viewModel.gameTime.description)")
                        .font(.headline)
                    Text("Is Night: \(viewModel.gameTime.isNightTime ? "Yes" : "No")")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // Player Info
                VStack(alignment: .leading, spacing: 10) {
                    Text("Player")
                        .font(.title)
                    Text("Name: \(viewModel.player.name)")
                    Text("Age: \(viewModel.player.age)")
                    Text("Profession: \(viewModel.player.profession)")
                    
                    VStack(alignment: .leading) {
                        Text("Blood Level: \(Int(viewModel.playerBloodPercentage))%")
                        ProgressView(value: viewModel.playerBloodPercentage, total: 100)
                            .tint(.red)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // NPCs
                VStack(alignment: .leading, spacing: 15) {
                    Text("NPCs")
                        .font(.title)
                    
                    ForEach(viewModel.npcs, id: \.id) { npc in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Name: \(npc.name)")
                            Text("Age: \(npc.age)")
                            Text("Profession: \(npc.profession)")
                            
                            VStack(alignment: .leading) {
                                Text("Blood Level: \(Int(viewModel.npcBloodPercentages[npc.id] ?? 0))%")
                                ProgressView(value: viewModel.npcBloodPercentages[npc.id] ?? 0, total: 100)
                                    .tint(.red)
                            }
                            
                            Button("Feed on \(npc.name)") {
                                viewModel.feedOnNPC(npc)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                // Debug Prompts
                VStack(alignment: .leading, spacing: 5) {
                    Text("Debug Log")
                        .font(.title)
                    
                    ForEach(viewModel.debugPrompts, id: \.self) { prompt in
                        Text(prompt)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    DebugView()
} 